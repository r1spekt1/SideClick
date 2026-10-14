import AppKit
import MouseCore
import os
import UserNotifications

private let log = Logger(subsystem: "com.r1spekt1.SideClick", category: "app")

/// Owns the settings and the system controllers; the single source of truth for the UI.
@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { settingsDidChange(from: oldValue) }
    }
    @Published private(set) var isAccessibilityGranted = Permissions.isAccessibilityGranted
    @Published private(set) var pressedButtons: Set<SideButton> = []
    @Published private(set) var connectedMice: [ConnectedMouse] = []
    var isMouseConnected: Bool { !connectedMice.isEmpty }
    var mouseTitle: String { MouseSummary.title(for: connectedMice.map(\.name)) }
    private var bluetoothMouseNames: [String] { connectedMice.filter { $0.connection == .bluetooth }.map(\.name) }
    @Published private(set) var conflicts: [String] = []
    @Published private(set) var battery: BatteryStatus?
    /// The WhiteShark receiver is connected but its battery can't be read without Input Monitoring.
    @Published private(set) var needsInputMonitoring = false
    /// A Bluetooth mouse is connected but the Bluetooth permission was denied.
    @Published private(set) var needsBluetooth = false

    private let store: SettingsStore
    private let buttons = ButtonController()
    private let scroll = ScrollController()
    private let device = DeviceMonitor()
    private let pointer = PointerController()
    private let batteryMonitor = BatteryMonitor()
    private let bluetoothBattery = BluetoothBatteryMonitor()
    private var lowBatteryAlert = LowBatteryAlert()
    private var observers: [NSObjectProtocol] = []
    private var terminateSources: [DispatchSourceSignal] = []
    private var permissionTimer: Timer?
    private var conflictTimer: Timer?

    init(store: SettingsStore = SettingsStore()) {
        do {
            try SupportDirectoryMigration.migrate(from: SettingsStore.legacySupportDirectoryURL,
                                                  to: SettingsStore.supportDirectoryURL)
        } catch {
            log.error("Migrating the old settings failed: \(error.localizedDescription)")
        }
        self.store = store
        settings = store.load()
        buttons.onButtonActivity = { [weak self] button, isDown in
            if isDown { self?.pressedButtons.insert(button) } else { self?.pressedButtons.remove(button) }
        }
        device.onChange = { [weak self] mice in
            guard let self else { return }
            self.connectedMice = mice
            self.bluetoothBattery.update(mouseNames: self.bluetoothMouseNames)
            self.batteryDidChange()
            if mice.isEmpty {
                self.pointer.deviceDisconnected()
            } else {
                self.applySettings()
                // The HID service can appear shortly after the device, so retry.
                for delay in [0.5, 2.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        MainActor.assumeIsolated { self?.applySettings() }
                    }
                }
            }
        }
        device.start()
        batteryMonitor.onChange = { [weak self] in self?.batteryDidChange() }
        bluetoothBattery.onChange = { [weak self] in self?.batteryDidChange() }
        batteryMonitor.start()
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.pointer.restore() }
        })
        // SIGTERM (e.g. pkill) and SIGINT (Ctrl-C) skip willTerminate; route them through a normal terminate.
        for signalNumber in [SIGTERM, SIGINT] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { NSApp.terminate(nil) }
            source.resume()
            terminateSources.append(source)
        }
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.applySettings()
                self?.batteryMonitor.refresh()
            }
        })
        if !isAccessibilityGranted { Permissions.requestAccessibility() }
        watchPermissions()
        applySettings()
        refreshConflicts()
        conflictTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshConflicts() }
        }
    }

    func requestAccessibility() {
        Permissions.requestAccessibility()
        Permissions.openAccessibilitySettings()
    }

    /// Called when the menu opens, so it never shows a reading that is several seconds old.
    func refreshBattery() {
        batteryMonitor.refresh()
    }

    func openBluetoothSettings() {
        Permissions.openBluetoothSettings()
    }

    func requestInputMonitoring() {
        Permissions.requestInputMonitoring()
        Permissions.openInputMonitoringSettings()
    }

    /// Keeps polling for the whole run: a revoked Accessibility permission must stop the HID taps,
    /// which could otherwise stall scrolling and the side buttons. Input Monitoring is polled so the
    /// battery shows up as soon as it is granted.
    private func watchPermissions() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.accessibilityMayHaveChanged()
                self?.inputMonitoringMayHaveChanged()
            }
        }
    }

    private func accessibilityMayHaveChanged() {
        let granted = Permissions.isAccessibilityGranted
        guard granted != isAccessibilityGranted else { return }
        isAccessibilityGranted = granted
        if granted {
            applySettings()
        } else {
            log.error("Accessibility permission was revoked; stopping the event taps")
            buttons.stop()
            scroll.stop()
        }
    }

    private func inputMonitoringMayHaveChanged() {
        guard needsInputMonitoring, Permissions.isInputMonitoringGranted else { return }
        needsInputMonitoring = false
        batteryMonitor.refresh()
    }

    /// The receiver's reading wins; otherwise the Bluetooth mouse's.
    private func batteryDidChange() {
        battery = batteryMonitor.status ?? bluetoothBattery.status
        needsInputMonitoring = batteryMonitor.isReceiverConnected && !Permissions.isInputMonitoringGranted
        needsBluetooth = !bluetoothMouseNames.isEmpty && bluetoothBattery.isDenied
        if let battery, lowBatteryAlert.shouldWarn(for: battery) { Self.notifyLowBattery(battery) }
    }

    private func settingsDidChange(from old: AppSettings) {
        guard settings != old else { return }
        do {
            try store.save(settings)
        } catch {
            log.error("Saving settings failed: \(error.localizedDescription)")
        }
        applySettings()
    }

    private func applySettings() {
        if settings.isEnabled { pointer.apply(settings.pointer) } else { pointer.restore() }
        guard isAccessibilityGranted else { return }
        guard settings.isEnabled else {
            buttons.stop()
            scroll.stop()
            return
        }
        buttons.update(settings: settings)
        scroll.update(settings: settings.scroll)
        if !buttons.start() { log.error("Could not create the side-button event tap") }
        if !scroll.start() { log.error("Could not create the scroll event tap") }
    }

    /// Asks for notification permission the first time it is needed. Notifications need a bundle,
    /// so an unbundled run (`swift run`) only logs.
    private static func notifyLowBattery(_ status: BatteryStatus) {
        guard Bundle.main.bundleIdentifier != nil else {
            log.info("Mouse battery low: \(status.percent)%")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Mouse battery low"
            content.body = "\(status.percent)% left. Charge the mouse soon."
            content.sound = .default
            let request = UNNotificationRequest(identifier: "low-battery", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func refreshConflicts() {
        let names = ConflictDetector.conflictingProcessNames()
        if names != conflicts { conflicts = names }
    }
}
