import AppKit
import MouseCore
import os

private let log = Logger(subsystem: "com.r1spekt1.SideClick", category: "app")

/// Owns the settings and the system controllers; the single source of truth for the UI.
@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { settingsDidChange(from: oldValue) }
    }
    @Published private(set) var isAccessibilityGranted = Permissions.isAccessibilityGranted
    @Published private(set) var pressedButtons: Set<SideButton> = []
    @Published private(set) var connectedMice: [String] = []
    var isMouseConnected: Bool { !connectedMice.isEmpty }
    var mouseTitle: String { MouseSummary.title(for: connectedMice) }
    @Published private(set) var conflicts: [String] = []

    private let store: SettingsStore
    private let buttons = ButtonController()
    private let scroll = ScrollController()
    private let device = DeviceMonitor()
    private let pointer = PointerController()
    private var observers: [NSObjectProtocol] = []
    private var terminateSources: [DispatchSourceSignal] = []
    private var permissionTimer: Timer?
    private var conflictTimer: Timer?

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        settings = store.load()
        buttons.onButtonActivity = { [weak self] button, isDown in
            if isDown { self?.pressedButtons.insert(button) } else { self?.pressedButtons.remove(button) }
        }
        device.onChange = { [weak self] names in
            guard let self else { return }
            self.connectedMice = names
            if names.isEmpty {
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
            MainActor.assumeIsolated { self?.applySettings() }
        })
        if !isAccessibilityGranted { Permissions.requestAccessibility() }
        watchAccessibility()
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

    /// Keeps polling for the whole run: a revoked permission must stop the HID taps,
    /// which could otherwise stall scrolling and the side buttons.
    private func watchAccessibility() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.accessibilityMayHaveChanged() }
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

    private func refreshConflicts() {
        let names = ConflictDetector.conflictingProcessNames()
        if names != conflicts { conflicts = names }
    }
}
