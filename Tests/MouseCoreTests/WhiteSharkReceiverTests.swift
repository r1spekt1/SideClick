import Testing
@testable import MouseCore

private func bytes(_ hex: String) -> [UInt8] {
    hex.split(separator: " ").map { UInt8($0, radix: 16)! }
}

/// Replies captured from the receiver (USB capture of the vendor software, and this Mac).
private let discharging68 = bytes("0c 01 20 00 01 01 10 00 4d 30 35 39 29 01 00 95 16 ff 44 00 ff 01 00 00 c6 28 28 37 ff c7 67 09 6d")
private let charging = bytes("0c 01 20 00 06 01 10 00 4d 30 35 39 29 01 00 95 16 ff 64 01 ff 01 00 00 c6 28 28 37 ff 22 01 20 38")

@Suite struct WhiteSharkReceiverTests {
    @Test func requestMatchesTheVendorSoftware() {
        let expected = bytes("0c 01 20 00 05") + [UInt8](repeating: 0, count: 28)
        #expect(WhiteSharkReceiver.statusRequest(sequence: 5) == expected)
    }

    @Test func dischargingReply() {
        #expect(WhiteSharkReceiver.battery(fromReply: discharging68, sequence: 1)
            == BatteryStatus(percent: 68, isCharging: false))
    }

    @Test func chargingReply() {
        #expect(WhiteSharkReceiver.battery(fromReply: charging, sequence: 6)
            == BatteryStatus(percent: 100, isCharging: true))
    }

    @Test func replyToAnotherSequenceIsRejected() {
        #expect(WhiteSharkReceiver.battery(fromReply: discharging68, sequence: 2) == nil)
    }

    @Test func emptyOrShortReplyIsRejected() {
        #expect(WhiteSharkReceiver.battery(fromReply: [], sequence: 1) == nil)
        #expect(WhiteSharkReceiver.battery(fromReply: Array(discharging68.prefix(19)), sequence: 1) == nil)
        #expect(WhiteSharkReceiver.battery(fromReply: [UInt8](repeating: 0, count: 33), sequence: 0) == nil)
    }

    @Test func errorStatusIsRejected() {
        var reply = discharging68
        reply[5] = 0x00
        #expect(WhiteSharkReceiver.battery(fromReply: reply, sequence: 1) == nil)
    }

    @Test func otherCommandIsRejected() {
        var reply = discharging68
        reply[2] = 0x0B
        #expect(WhiteSharkReceiver.battery(fromReply: reply, sequence: 1) == nil)
    }

    @Test func impossibleLevelIsRejected() {
        var reply = discharging68
        reply[18] = 101
        #expect(WhiteSharkReceiver.battery(fromReply: reply, sequence: 1) == nil)
    }
}
