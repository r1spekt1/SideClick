// Prints the pointer HID properties of the Xiaomi mouse service.
// Run: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift scripts/pointer-props.swift
import Foundation
import IOKit.hidsystem

let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] ?? []
for service in services where (IOHIDServiceClientCopyProperty(service, "VendorID" as CFString) as? Int) == 0x2717 {
    for key in ["Product", "PrimaryUsage", "HIDMouseAcceleration", "HIDPointerResolution"] {
        print(key, "=", IOHIDServiceClientCopyProperty(service, key as CFString).map { "\($0)" } ?? "nil")
    }
    print("---")
}
