import Foundation
import IOKit.hid
import MouseCore

/// Reports which external mice are connected. Matching only; never opens a device,
/// so no Input Monitoring permission is needed.
@MainActor
final class DeviceMonitor {
    /// Called with the sorted product names of the connected external mice whenever that list changes.
    var onChange: (([String]) -> Void)?
    private(set) var mouseNames: [String] = []

    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    /// The same IOHIDDevice object is passed to the match and the removal callback.
    private var devices: [ObjectIdentifier: String] = [:]

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
        devices[ObjectIdentifier(device)] = info.productName
        publish()
    }

    private func deviceRemoved(_ device: IOHIDDevice) {
        guard devices.removeValue(forKey: ObjectIdentifier(device)) != nil else { return }
        publish()
    }

    private func publish() {
        let names = devices.values.sorted()
        guard names != mouseNames else { return }
        mouseNames = names
        onChange?(names)
    }
}
