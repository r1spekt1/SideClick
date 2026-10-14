import Foundation
import IOKit.hid
import MouseCore
import os

/// Reads the battery of a WhiteShark Maximus through its 2.4 GHz receiver, every few seconds and on
/// demand. Sends only the receiver's status query (see `WhiteSharkReceiver`). The query needs the
/// receiver's keyboard interface open (shared, not seized), which macOS allows only with the
/// Input Monitoring permission.
///
/// On its cable the mouse leaves the 2.4 GHz link and the receiver keeps reporting its last level,
/// so while the wired mouse is connected the status is "charging" without asking the receiver.
@MainActor
final class BatteryMonitor {
    /// Called whenever `status` or `isReceiverConnected` changes.
    var onChange: (() -> Void)?
    /// nil while no receiver is connected, the permission is missing or the read failed.
    private(set) var status: BatteryStatus?
    private(set) var isReceiverConnected = false

    private static let pollInterval: TimeInterval = 10
    /// The vendor software waits about 15 ms between the query and reading the reply.
    private static let replyDelay: TimeInterval = 0.05
    private static let charging = BatteryStatus(percent: 100, isCharging: true)

    private let log = Logger(subsystem: "com.r1spekt1.SideClick", category: "battery")
    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    private var receiver: IOHIDDevice? {
        didSet {
            isReceiverConnected = receiver != nil
            isReceiverOpen = false
        }
    }
    private var isReceiverOpen = false
    private var wiredMouse: IOHIDDevice?
    private var sequence: UInt8 = 0
    private var timer: Timer?

    func start() {
        // One interface of each: the receiver's keyboard interface holds the status report.
        let matching = [WhiteSharkReceiver.productID, WhiteSharkReceiver.wiredMouseProductID].map {
            [kIOHIDVendorIDKey: WhiteSharkReceiver.vendorID,
             kIOHIDProductIDKey: $0,
             kIOHIDPrimaryUsagePageKey: HIDDeviceInfo.genericDesktopPage,
             kIOHIDPrimaryUsageKey: kHIDUsage_GD_Keyboard]
        }
        IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.deviceAdded(device) }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.deviceRemoved(device) }
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    /// Queries the receiver now, and publishes the reply shortly after.
    func refresh() {
        guard wiredMouse == nil, let receiver, Permissions.isInputMonitoringGranted, openReceiver(receiver)
        else { return }
        sequence &+= 1
        let sequence = sequence
        let request = WhiteSharkReceiver.statusRequest(sequence: sequence)
        let result = IOHIDDeviceSetReport(receiver, kIOHIDReportTypeFeature, CFIndex(WhiteSharkReceiver.reportID),
                                          request, request.count)
        guard result == kIOReturnSuccess else {
            log.error("Battery query failed: \(String(format: "0x%08x", result), privacy: .public)")
            publish(nil)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.replyDelay) { [weak self] in
            MainActor.assumeIsolated { self?.readReply(from: receiver, sequence: sequence) }
        }
    }

    private func openReceiver(_ device: IOHIDDevice) -> Bool {
        guard !isReceiverOpen else { return true }
        let result = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            log.error("Opening the receiver failed: \(String(format: "0x%08x", result), privacy: .public)")
            return false
        }
        isReceiverOpen = true
        return true
    }

    private func readReply(from device: IOHIDDevice, sequence: UInt8) {
        guard device === receiver, wiredMouse == nil else { return }
        var reply = [UInt8](repeating: 0, count: WhiteSharkReceiver.reportLength)
        var length = reply.count
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, CFIndex(WhiteSharkReceiver.reportID),
                                          &reply, &length)
        guard result == kIOReturnSuccess else {
            log.error("Reading the battery reply failed: \(String(format: "0x%08x", result), privacy: .public)")
            publish(nil)
            return
        }
        let bytes = Array(reply.prefix(length))
        let battery = WhiteSharkReceiver.battery(fromReply: bytes, sequence: sequence)
        if battery == nil {
            let hex = bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
            log.error("Unrecognized battery reply to query \(sequence, privacy: .public): \(hex, privacy: .public)")
        }
        publish(battery)
    }

    private func deviceAdded(_ device: IOHIDDevice) {
        if HIDDeviceInfo(device: device).productID == WhiteSharkReceiver.wiredMouseProductID {
            wiredMouse = device
            publish(Self.charging)
        } else {
            receiver = device
            onChange?()
            refresh()
        }
    }

    private func deviceRemoved(_ device: IOHIDDevice) {
        if device === wiredMouse {
            wiredMouse = nil
            publish(nil)
            refresh()
        } else if device === receiver {
            receiver = nil
            status = wiredMouse == nil ? nil : Self.charging
            onChange?()
        }
    }

    private func publish(_ newStatus: BatteryStatus?) {
        guard newStatus != status else { return }
        status = newStatus
        onChange?()
    }
}
