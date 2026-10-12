// THROWAWAY SPIKE: logs raw HID reports from the Xiaomi mouse + system events seen by an event tap.
import Foundation
import IOKit.hid
import CoreGraphics

setvbuf(stdout, nil, _IOLBF, 0)

let start = Date()
func ts() -> String { String(format: "%8.3f", Date().timeIntervalSince(start)) }

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey: 0x2717, kIOHIDProductIDKey: 0x5013] as CFDictionary)

let reportCallback: IOHIDReportCallback = { _, _, _, _, reportID, report, length in
    let bytes = (0..<length).map { String(format: "%02x", report[$0]) }.joined(separator: " ")
    // Skip pure-motion report 1 noise unless the button byte is non-zero.
    if reportID == 1 && length > 1 && report[1] == 0 { return }
    print("\(ts()) HID report id=\(reportID) len=\(length): \(bytes)")
}

let valueCallback: IOHIDValueCallback = { _, _, _, value in
    let el = IOHIDValueGetElement(value)
    let page = IOHIDElementGetUsagePage(el), usage = IOHIDElementGetUsage(el)
    let v = IOHIDValueGetIntegerValue(value)
    if page == 0x01 && (usage == 0x30 || usage == 0x31) { return } // X/Y motion
    if v == 0 && page != 0x09 { return }
    print("\(ts()) HID value page=0x\(String(page, radix: 16)) usage=0x\(String(usage, radix: 16)) value=\(v)")
}

let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
IOHIDManagerRegisterDeviceMatchingCallback(manager, { _, _, _, device in
    let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "?"
    let usage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsageKey as CFString) as? Int ?? -1
    let page = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? -1
    print("\(ts()) device matched: \(name) primaryPage=0x\(String(page, radix: 16)) usage=0x\(String(usage, radix: 16))")
    IOHIDDeviceRegisterInputReportCallback(device, buf, 64, reportCallback, nil)
}, nil)
IOHIDManagerRegisterInputValueCallback(manager, valueCallback, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
print("IOHIDRequestAccess(listen) = \(IOHIDRequestAccess(kIOHIDRequestTypeListenEvent))")
let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
print("IOHIDManagerOpen = 0x\(String(UInt32(bitPattern: openResult), radix: 16)) (0 = ok, 0xe00002e2 = no Input Monitoring permission)")

// Event tap: see what the system turns those reports into.
let types: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .otherMouseDown, .otherMouseUp, .leftMouseDown, .rightMouseDown]
var mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
mask |= 1 << 14 // NX_SYSDEFINED (media / consumer keys)
let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                            eventsOfInterest: mask, callback: { _, type, event, _ in
    switch type.rawValue {
    case 14:
        let data1 = event.getIntegerValueField(CGEventField(rawValue: 149)!) // NSEvent data1
        let key = (data1 & 0xFFFF0000) >> 16, flags = data1 & 0xFFFF
        print("\(ts()) TAP systemDefined subtype=\(event.getIntegerValueField(CGEventField(rawValue: 99)!)) key=\(key) state=0x\(String(flags, radix: 16))")
    case CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue:
        print("\(ts()) TAP \(type == .keyDown ? "keyDown" : "keyUp") keycode=\(event.getIntegerValueField(.keyboardEventKeycode)) flags=0x\(String(event.flags.rawValue, radix: 16))")
    case CGEventType.otherMouseDown.rawValue, CGEventType.otherMouseUp.rawValue:
        print("\(ts()) TAP \(type == .otherMouseDown ? "otherMouseDown" : "otherMouseUp") button=\(event.getIntegerValueField(.mouseEventButtonNumber))")
    default:
        print("\(ts()) TAP type=\(type.rawValue)")
    }
    return Unmanaged.passUnretained(event)
}, userInfo: nil)
if let tap {
    CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    print("event tap = ok")
} else {
    print("event tap = FAILED (needs Accessibility / Input Monitoring)")
}

print("Listening... press side buttons.")
CFRunLoopRun()
