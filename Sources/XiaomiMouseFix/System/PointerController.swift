import Foundation
import IOKit.hidsystem
import MouseCore

/// Applies pointer speed/acceleration to the Xiaomi HID service only and restores the
/// values the system had before we touched it.
@MainActor
final class PointerController {
    private let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
    /// System values captured before the first change on the current connection.
    private var originals: [String: CFTypeRef]?

    func apply(_ settings: PointerSettings) {
        guard settings.isCustomized else {
            restore()
            return
        }
        let services = xiaomiServices()
        guard let first = services.first else { return }
        if originals == nil { originals = capture(first) }
        let props = PointerProperties(settings: settings)
        for service in services {
            set(service, PointerProperties.accelerationKey, props.acceleration)
            set(service, PointerProperties.resolutionKey, props.resolution)
        }
    }

    func restore() {
        guard let originals else { return }
        for service in xiaomiServices() {
            for (key, value) in originals {
                IOHIDServiceClientSetProperty(service, key as CFString, value)
            }
        }
        self.originals = nil
    }

    /// A reconnected mouse starts from fresh system values, so capture them again.
    func deviceDisconnected() {
        originals = nil
    }

    private func capture(_ service: IOHIDServiceClient) -> [String: CFTypeRef] {
        var values: [String: CFTypeRef] = [
            PointerProperties.resolutionKey: NSNumber(value: PointerProperties.defaultResolution),
        ]
        for key in [PointerProperties.accelerationKey, PointerProperties.resolutionKey] {
            if let value = IOHIDServiceClientCopyProperty(service, key as CFString) { values[key] = value }
        }
        return values
    }

    private func set(_ service: IOHIDServiceClient, _ key: String, _ value: Int) {
        IOHIDServiceClientSetProperty(service, key as CFString, NSNumber(value: value))
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
