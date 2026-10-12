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

    private let store: SettingsStore
    private var permissionTimer: Timer?

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        settings = store.load()
        if !isAccessibilityGranted {
            Permissions.requestAccessibility()
            pollForAccessibility()
        }
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
    }
}
