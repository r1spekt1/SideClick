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
    /// The HID calls are asynchronous with a timeout (in milliseconds, per IOHIDDevice.h), because
    /// the side-button and scroll event taps share the main run loop and must never wait on USB.
    private static let timeoutMilliseconds: CFTimeInterval = 500
    private static let charging = BatteryStatus(percent: 100, isCharging: true)

    private let log = Logger(subsystem: "com.r1spekt1.SideClick", category: "battery")
    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    private var receiver: IOHIDDevice? {
        didSet {
            isReceiverConnected = receiver != nil
            isReceiverOpen = false
            pendingSequence = nil
        }
    }
    private var isReceiverOpen = false
    /// The query in flight; refreshes are skipped meanwhile so replies never cross.
    private var pendingSequence: UInt8?
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

    /// Queries the receiver now, unless a query is already in flight, and publishes the reply.
    func refresh() {
        guard wiredMouse == nil, let receiver, pendingSequence == nil else { return }
        guard Permissions.isInputMonitoringGranted, openReceiver(receiver) else {
            // Clears an old level, and lets AppModel bring back the Grant button.
            publish(nil)
            return
        }
        sequence &+= 1
        let query = Query(device: receiver, sequence: sequence, monitor: self)
        query.buffer.update(from: WhiteSharkReceiver.statusRequest(sequence: sequence),
                            count: WhiteSharkReceiver.reportLength)
        pendingSequence = sequence
        let context = Unmanaged.passRetained(query).toOpaque()
        let result = IOHIDDeviceSetReportWithCallback(
            receiver, kIOHIDReportTypeFeature, CFIndex(WhiteSharkReceiver.reportID), query.buffer,
            WhiteSharkReceiver.reportLength, Self.timeoutMilliseconds, { context, result, _, _, _, _, _ in
                let query = Unmanaged<Query>.fromOpaque(context!).takeRetainedValue()
                MainActor.assumeIsolated { query.monitor?.querySent(query, result: result) }
            }, context)
        if result != kIOReturnSuccess {
            Unmanaged<Query>.fromOpaque(context).release()
            fail(query, "Battery query", result)
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

    private func querySent(_ query: Query, result: IOReturn) {
        guard isCurrent(query) else { return }
        guard result == kIOReturnSuccess else { return fail(query, "Battery query", result) }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.replyDelay) { [weak self] in
            MainActor.assumeIsolated { self?.readReply(query) }
        }
    }

    private func readReply(_ query: Query) {
        guard isCurrent(query) else { return }
        query.length.pointee = WhiteSharkReceiver.reportLength
        let context = Unmanaged.passRetained(query).toOpaque()
        let result = IOHIDDeviceGetReportWithCallback(
            query.device, kIOHIDReportTypeFeature, CFIndex(WhiteSharkReceiver.reportID), query.buffer, query.length,
            Self.timeoutMilliseconds, { context, result, _, _, _, _, _ in
                let query = Unmanaged<Query>.fromOpaque(context!).takeRetainedValue()
                MainActor.assumeIsolated { query.monitor?.replyReceived(query, result: result) }
            }, context)
        if result != kIOReturnSuccess {
            Unmanaged<Query>.fromOpaque(context).release()
            fail(query, "Reading the battery reply", result)
        }
    }

    private func replyReceived(_ query: Query, result: IOReturn) {
        guard isCurrent(query) else { return }
        guard result == kIOReturnSuccess else { return fail(query, "Reading the battery reply", result) }
        pendingSequence = nil
        let bytes = Array(UnsafeBufferPointer(start: query.buffer, count: max(0, query.length.pointee)))
        // A reply to an earlier query is stale, not a failure: keep the level shown.
        if bytes.count > 4, bytes[4] != query.sequence { return }
        let battery = WhiteSharkReceiver.battery(fromReply: bytes, sequence: query.sequence)
        if battery == nil {
            let hex = bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
            log.error("Unrecognized battery reply to query \(query.sequence, privacy: .public): \(hex, privacy: .public)")
        }
        publish(battery)
    }

    /// False once the query was abandoned: the receiver went away or the wired mouse took over.
    private func isCurrent(_ query: Query) -> Bool {
        pendingSequence == query.sequence && query.device === receiver && wiredMouse == nil
    }

    private func fail(_ query: Query, _ step: String, _ result: IOReturn) {
        guard pendingSequence == query.sequence else { return }
        pendingSequence = nil
        log.error("\(step, privacy: .public) failed: \(String(format: "0x%08x", result), privacy: .public)")
        publish(nil)
    }

    private func deviceAdded(_ device: IOHIDDevice) {
        if HIDDeviceInfo(device: device).productID == WhiteSharkReceiver.wiredMouseProductID {
            wiredMouse = device
            pendingSequence = nil
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

/// One status query in flight. The HID calls write into its buffers asynchronously, so each call
/// retains it as the callback context until its callback runs.
private final class Query {
    let device: IOHIDDevice
    let sequence: UInt8
    weak var monitor: BatteryMonitor?
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: WhiteSharkReceiver.reportLength)
    let length = UnsafeMutablePointer<CFIndex>.allocate(capacity: 1)

    init(device: IOHIDDevice, sequence: UInt8, monitor: BatteryMonitor) {
        self.device = device
        self.sequence = sequence
        self.monitor = monitor
        buffer.initialize(repeating: 0, count: WhiteSharkReceiver.reportLength)
        length.initialize(to: WhiteSharkReceiver.reportLength)
    }

    deinit {
        buffer.deallocate()
        length.deallocate()
    }
}
