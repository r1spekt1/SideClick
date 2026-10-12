import Foundation
import IOKit.hid

/// Reports whether the Xiaomi mouse is connected. Matching only; never opens the device,
/// so no Input Monitoring permission is needed.
@MainActor
final class DeviceMonitor {
    static let vendorID = 0x2717
    static let productID = 0x5013

    var onChange: ((Bool) -> Void)?
    private(set) var isConnected = false

    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    private var deviceCount = 0

    func start() {
        IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey: Self.vendorID,
                                                kIOHIDProductIDKey: Self.productID] as CFDictionary)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, _ in
            guard let context else { return }
            let monitor = Unmanaged<DeviceMonitor>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.deviceCountChanged(by: 1) }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, _ in
            guard let context else { return }
            let monitor = Unmanaged<DeviceMonitor>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.deviceCountChanged(by: -1) }
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    private func deviceCountChanged(by change: Int) {
        deviceCount = max(0, deviceCount + change)
        let connected = deviceCount > 0
        guard connected != isConnected else { return }
        isConnected = connected
        onChange?(connected)
    }
}
