// Prints the pointer HID properties of every mouse service.
// Run: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift scripts/pointer-props.swift
import Foundation
import IOKit.hidsystem

let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] ?? []
for service in services
where (IOHIDServiceClientCopyProperty(service, "PrimaryUsagePage" as CFString) as? Int) == 1
    && (IOHIDServiceClientCopyProperty(service, "PrimaryUsage" as CFString) as? Int) == 2 {
    for key in ["Product", "VendorID", "ProductID", "PrimaryUsagePage", "PrimaryUsage", "Built-In",
                "HIDMouseAcceleration", "HIDPointerResolution",
                "HIDUseLinearScalingMouseAcceleration"] {
        print(key, "=", IOHIDServiceClientCopyProperty(service, key as CFString).map { "\($0)" } ?? "nil")
    }
    print("---")
}
