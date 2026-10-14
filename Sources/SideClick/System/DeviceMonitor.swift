import Foundation
import IOKit.hid
import MouseCore

/// Reports which external mice are connected. Matching only; never opens a device,
/// so no Input Monitoring permission is needed.
@MainActor
final class DeviceMonitor {
    /// Called with the connected external mice, sorted by name and then by the link in use,
    /// whenever that list changes.
    var onChange: (([ConnectedMouse]) -> Void)?
    private(set) var mice: [ConnectedMouse] = []

    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    /// The same IOHIDDevice object is passed to the match and the removal callback.
    private var devices: [ObjectIdentifier: ConnectedMouse] = [:]

    func start() {
        IOHIDManagerSetDeviceMatching(manager, [kIOHIDPrimaryUsagePageKey: HIDDeviceInfo.genericDesktopPage,
                                                kIOHIDPrimaryUsageKey: HIDDeviceInfo.mouseUsage] as CFDictionary)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            let monitor = Unmanaged<DeviceMonitor>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.deviceAdded(device) }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            let monitor = Unmanaged<DeviceMonitor>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.deviceRemoved(device) }
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    private func deviceAdded(_ device: IOHIDDevice) {
        let info = HIDDeviceInfo(device: device)
        guard info.isExternalMouse else { return }
        devices[ObjectIdentifier(device)] = ConnectedMouse(name: info.productName, connection: info.connection)
        publish()
    }

    private func deviceRemoved(_ device: IOHIDDevice) {
        guard devices.removeValue(forKey: ObjectIdentifier(device)) != nil else { return }
        publish()
    }

    private func publish() {
        let sorted = ConnectedMouse.sorted(devices.values)
        guard sorted != mice else { return }
        mice = sorted
        onChange?(sorted)
    }
}
