import Foundation
import IOKit.hidsystem
import MouseCore
import os

/// Applies the tracking speed (acceleration) to every external mouse's HID service and restores the
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

    private let log = Logger(subsystem: "com.r1spekt1.SideClick", category: "pointer")
    private let client = PointerController.makeClient()
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
        let props = PointerProperties(settings: settings)
        for target in targets {
            rememberOriginals(of: target)
            set(target.service, PointerProperties.accelerationKey, props.acceleration)
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
            guard var values = pending[target.key] else { continue }
            // Values saved by earlier versions can hold a resolution; hidd picks it up only with
            // an acceleration write after it.
            if values[PointerProperties.accelerationKey] == nil,
               let current = IOHIDServiceClientCopyProperty(target.service, PointerProperties.accelerationKey as CFString) as? Int {
                values[PointerProperties.accelerationKey] = current
            }
            for (key, value) in PointerProperties.writeOrder(values) {
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

    private func rememberOriginals(of target: Target) {
        guard originals[target.key] == nil else { return }
        var saved = store.load() ?? PointerOriginals()
        if let values = saved[target.key] {
            originals[target.key] = values
            return
        }
        var captured: PointerOriginals.Values = [:]
        if let value = IOHIDServiceClientCopyProperty(target.service, PointerProperties.accelerationKey as CFString) as? Int {
            captured[PointerProperties.accelerationKey] = value
        }
        originals[target.key] = captured
        saved[target.key] = captured
        persist(saved)
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

    /// A simple client sees only part of a service's properties: in the app it could not read the
    /// vendor and product IDs or set `HIDMouseAcceleration` (observed on macOS 27). A passive client
    /// gets the full property set without receiving events. Its constructor is not in the public
    /// headers; the simple client is the fallback.
    private static func makeClient() -> IOHIDEventSystemClient {
        IOHIDEventSystemClientCreateWithType(kCFAllocatorDefault, passiveClientType, nil)
            ?? IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
    }

    private static let passiveClientType: Int32 = 2

    private func mouseServices() -> [Target] {
        let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] ?? []
        return services.compactMap { service in
            let info = HIDDeviceInfo(service: service)
            return info.isExternalMouse ? Target(service: service, key: info.key) : nil
        }
    }
}

@_silgen_name("IOHIDEventSystemClientCreateWithType")
private func IOHIDEventSystemClientCreateWithType(_ allocator: CFAllocator?, _ type: Int32,
                                                  _ attributes: CFDictionary?) -> IOHIDEventSystemClient?
