import Foundation
import IOKit.hid
import IOKit.hidsystem
import MouseCore

extension HIDDeviceInfo {
    /// Reads the properties through `property`, so devices and HID services share one code path.
    private init(property: (String) -> Any?) {
        func int(_ key: String) -> Int { property(key) as? Int ?? 0 }
        self.init(vendorID: int(kIOHIDVendorIDKey),
                  productID: int(kIOHIDProductIDKey),
                  productName: property(kIOHIDProductKey) as? String ?? "",
                  primaryUsagePage: int(kIOHIDPrimaryUsagePageKey),
                  primaryUsage: int(kIOHIDPrimaryUsageKey),
                  isBuiltIn: int("Built-In") == 1)
    }

    init(device: IOHIDDevice) {
        self.init(property: { IOHIDDeviceGetProperty(device, $0 as CFString) })
    }

    init(service: IOHIDServiceClient) {
        self.init(property: { IOHIDServiceClientCopyProperty(service, $0 as CFString) })
    }
}
