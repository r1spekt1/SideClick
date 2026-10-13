import Foundation
import IOKit.hidsystem
import MouseCore
import os

/// Applies pointer speed/acceleration to every external mouse's HID service and restores the
/// values the system had before we touched it. Originals are kept per device model, and also on
/// disk, so a crashed or killed run does not leave the next launch capturing our custom values.
@MainActor
final class PointerController {
    nonisolated static var defaultOriginalsURL: URL {
        SettingsStore.defaultFileURL.deletingLastPathComponent().appendingPathComponent("pointer-originals.json")
    }

    private struct Target {
        let service: IOHIDServiceClient
        let key: String
    }

    private let log = Logger(subsystem: "com.local.XiaomiMouseFix", category: "pointer")
    private let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
    private let store: PointerOriginalsStore
    /// System values captured before the first change on the current connection, per device key.
    private var originals = PointerOriginals()

    init(originalsURL: URL = PointerController.defaultOriginalsURL) {
        store = PointerOriginalsStore(fileURL: originalsURL)
    }

    func apply(_ settings: PointerSettings) {
        guard settings.isCustomized else {
            restore()
            return
        }
        let targets = mouseServices()
        guard !targets.isEmpty else {
            log.info("Pointer customization is on but no external mouse HID service is listed yet")
            return
        }
        for target in targets {
            let values = originalValues(for: target)
            let native = values[PointerProperties.resolutionKey] ?? PointerProperties.defaultResolution
            let props = PointerProperties(settings: settings, nativeResolution: native)
            set(target.service, PointerProperties.accelerationKey, props.acceleration)
            set(target.service, PointerProperties.resolutionKey, props.resolution)
        }
    }

    func restore() {
        // After a crash only the file still knows the values from before our change.
        var pending = store.load() ?? PointerOriginals()
        for (key, values) in originals.devices { pending[key] = values }
        guard !pending.isEmpty else { return }

        var restored: Set<String> = []
        var failed: Set<String> = []
        for target in mouseServices() {
            guard let values = pending[target.key] else { continue }
            for (key, value) in values {
                if IOHIDServiceClientSetProperty(target.service, key as CFString, NSNumber(value: value)) {
                    restored.insert(target.key)
                } else {
                    log.error("Restoring \(key) to \(value) failed")
                    failed.insert(target.key)
                }
            }
        }
        originals = PointerOriginals()
        // Keep a device's saved values until they actually reached its service (it can be listed
        // late, or be unplugged right now).
        forgetSaved(restored.subtracting(failed))
    }

    /// Forgets the in-memory copy only: the saved snapshot from before our change is still
    /// the right value to restore once the mouse is back.
    func deviceDisconnected() {
        originals = PointerOriginals()
    }

    private func originalValues(for target: Target) -> PointerOriginals.Values {
        if let values = originals[target.key] { return values }
        var saved = store.load() ?? PointerOriginals()
        if let values = saved[target.key] {
            originals[target.key] = values
            return values
        }
        let captured = capture(target.service)
        originals[target.key] = captured
        saved[target.key] = captured
        persist(saved)
        return captured
    }

    private func capture(_ service: IOHIDServiceClient) -> PointerOriginals.Values {
        var values = [PointerProperties.resolutionKey: PointerProperties.defaultResolution]
        for key in [PointerProperties.accelerationKey, PointerProperties.resolutionKey] {
            if let value = IOHIDServiceClientCopyProperty(service, key as CFString) as? Int { values[key] = value }
        }
        return values
    }

    private func persist(_ saved: PointerOriginals) {
        do {
            try store.save(saved)
        } catch {
            log.error("Saving pointer originals failed: \(error.localizedDescription)")
        }
    }

    private func forgetSaved(_ keys: Set<String>) {
        guard !keys.isEmpty, var saved = store.load() else { return }
        for key in keys { saved[key] = nil }
        do {
            if saved.isEmpty { try store.remove() } else { try store.save(saved) }
        } catch {
            log.error("Updating pointer originals failed: \(error.localizedDescription)")
        }
    }

    private func set(_ service: IOHIDServiceClient, _ key: String, _ value: Int) {
        if !IOHIDServiceClientSetProperty(service, key as CFString, NSNumber(value: value)) {
            log.error("Setting \(key) to \(value) failed")
        }
    }

    private func mouseServices() -> [Target] {
        let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] ?? []
        return services.compactMap { service in
            let info = HIDDeviceInfo(service: service)
            return info.isExternalMouse ? Target(service: service, key: info.key) : nil
        }
    }
}
