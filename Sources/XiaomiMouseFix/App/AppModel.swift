import AppKit
import MouseCore
import os

private let log = Logger(subsystem: "com.local.XiaomiMouseFix", category: "app")

/// Owns the settings and the system controllers; the single source of truth for the UI.
@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { settingsDidChange(from: oldValue) }
    }
    @Published private(set) var isAccessibilityGranted = Permissions.isAccessibilityGranted
    @Published private(set) var pressedButtons: Set<SideButton> = []
    @Published private(set) var isMouseConnected = false

    private let store: SettingsStore
    private let buttons = ButtonController()
    private let scroll = ScrollController()
    private let device = DeviceMonitor()
    private let pointer = PointerController()
    private var observers: [NSObjectProtocol] = []
    private var terminateSource: DispatchSourceSignal?
    private var permissionTimer: Timer?

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        settings = store.load()
        buttons.onButtonActivity = { [weak self] button, isDown in
            if isDown { self?.pressedButtons.insert(button) } else { self?.pressedButtons.remove(button) }
        }
        device.onChange = { [weak self] connected in
            guard let self else { return }
            self.isMouseConnected = connected
            if connected {
                self.applySettings()
                // The HID service can appear shortly after the device, so retry.
                for delay in [0.5, 2.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        MainActor.assumeIsolated { self?.applySettings() }
                    }
                }
            } else {
                self.pointer.deviceDisconnected()
            }
        }
        device.start()
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.pointer.restore() }
        })
        // SIGTERM (e.g. pkill) skips willTerminate; route it through a normal terminate.
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { NSApp.terminate(nil) }
        source.resume()
        terminateSource = source
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.applySettings() }
        })
        if !isAccessibilityGranted {
            Permissions.requestAccessibility()
            pollForAccessibility()
        }
        applySettings()
    }

    func requestAccessibility() {
        Permissions.requestAccessibility()
        Permissions.openAccessibilitySettings()
    }

    private func pollForAccessibility() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, Permissions.isAccessibilityGranted else { return }
                timer.invalidate()
                self.isAccessibilityGranted = true
                self.applySettings()
            }
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
}
