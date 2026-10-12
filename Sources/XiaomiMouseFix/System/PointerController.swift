import Foundation
import IOKit.hidsystem
import MouseCore
import os

/// Applies pointer speed/acceleration to the Xiaomi HID service only and restores the
/// values the system had before we touched it. The captured values are also kept on disk,
/// so a crashed or killed run does not leave the next launch capturing our custom values.
@MainActor
final class PointerController {
    nonisolated static var defaultOriginalsURL: URL {
        SettingsStore.defaultFileURL.deletingLastPathComponent().appendingPathComponent("pointer-originals.json")
    }

    private let log = Logger(subsystem: "com.local.XiaomiMouseFix", category: "pointer")
    private let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
    private let originalsURL: URL
    /// System values captured before the first change on the current connection.
    private var originals: [String: Int]?

    init(originalsURL: URL = PointerController.defaultOriginalsURL) {
        self.originalsURL = originalsURL
    }

    func apply(_ settings: PointerSettings) {
        guard settings.isCustomized else {
            restore()
            return
        }
        let services = xiaomiServices()
        guard let first = services.first else {
            log.info("Pointer customization is on but no Xiaomi HID service is listed yet")
            return
        }
        if originals == nil {
            if let saved = loadSavedOriginals() {
                originals = saved
            } else {
                let captured = capture(first)
                originals = captured
                save(captured)
            }
        }
        let props = PointerProperties(settings: settings)
        for service in services {
            set(service, PointerProperties.accelerationKey, props.acceleration)
            set(service, PointerProperties.resolutionKey, props.resolution)
        }
    }

    func restore() {
        // After a crash only the file still knows the values from before our change.
        guard let originals = originals ?? loadSavedOriginals() else { return }
        let services = xiaomiServices()
        // Keep the file until the values actually reached a service (it can be listed late).
        var succeeded = !services.isEmpty
        for service in services {
            for (key, value) in originals {
                if !IOHIDServiceClientSetProperty(service, key as CFString, NSNumber(value: value)) {
                    log.error("Restoring \(key) to \(value) failed")
                    succeeded = false
                }
            }
        }
        self.originals = nil
        if succeeded { removeSavedOriginals() }
    }

    /// Forgets the in-memory copy only: the saved snapshot from before our change is still
    /// the right value to restore once the mouse is back.
    func deviceDisconnected() {
        originals = nil
    }

    private func capture(_ service: IOHIDServiceClient) -> [String: Int] {
        var values = [PointerProperties.resolutionKey: PointerProperties.defaultResolution]
        for key in [PointerProperties.accelerationKey, PointerProperties.resolutionKey] {
            if let value = IOHIDServiceClientCopyProperty(service, key as CFString) as? Int { values[key] = value }
        }
        return values
    }

    private func loadSavedOriginals() -> [String: Int]? {
        guard let data = try? Data(contentsOf: originalsURL) else { return nil }
        return try? JSONDecoder().decode([String: Int].self, from: data)
    }

    private func save(_ values: [String: Int]) {
        do {
            try FileManager.default.createDirectory(at: originalsURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(values).write(to: originalsURL, options: .atomic)
        } catch {
            log.error("Saving pointer originals failed: \(error.localizedDescription)")
        }
    }

    private func removeSavedOriginals() {
        guard FileManager.default.fileExists(atPath: originalsURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: originalsURL)
        } catch {
            log.error("Removing pointer originals failed: \(error.localizedDescription)")
        }
    }

    private func set(_ service: IOHIDServiceClient, _ key: String, _ value: Int) {
        if !IOHIDServiceClientSetProperty(service, key as CFString, NSNumber(value: value)) {
            log.error("Setting \(key) to \(value) failed")
        }
    }

    private func xiaomiServices() -> [IOHIDServiceClient] {
        let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] ?? []
        return services.filter { service in
            intProperty(service, kIOHIDVendorIDKey) == DeviceMonitor.vendorID
                && intProperty(service, kIOHIDProductIDKey) == DeviceMonitor.productID
                && intProperty(service, kIOHIDPrimaryUsagePageKey) == kHIDPage_GenericDesktop
                && intProperty(service, kIOHIDPrimaryUsageKey) == kHIDUsage_GD_Mouse
        }
    }

    private func intProperty(_ service: IOHIDServiceClient, _ key: String) -> Int? {
        IOHIDServiceClientCopyProperty(service, key as CFString) as? Int
    }
}
