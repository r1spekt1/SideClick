/// The status query of the WhiteShark Maximus 2.4 GHz receiver (Telink, "SSCYPL Wireless-Receiver").
/// Taken from a USB capture of the vendor's Windows software: it SETs feature report 0x0C with
/// command 0x20 on the receiver's keyboard interface, then GETs the same report for the reply.
/// Only this read-only query is ever sent; the software's other commands change mouse settings.
public enum WhiteSharkReceiver {
    public static let vendorID = 0x248A
    public static let productID = 0x5B2F
    /// The mouse itself while it is connected by its charging cable.
    public static let wiredMouseProductID = 0x5B2E
    public static let reportID: UInt8 = 0x0C
    public static let reportLength = 33

    private static let statusCommand: UInt8 = 0x20
    private static let replyOK: UInt8 = 0x01
    private static let percentIndex = 18
    private static let chargingIndex = 19

    /// The query for one status read. The receiver echoes `sequence` in its reply.
    public static func statusRequest(sequence: UInt8) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: reportLength)
        report[0] = reportID
        report[1] = 0x01
        report[2] = statusCommand
        report[4] = sequence
        return report
    }

    /// The battery from a reply to `statusRequest(sequence:)`, or nil when the reply is for
    /// another command or request, reports an error, or holds an impossible level.
    public static func battery(fromReply reply: [UInt8], sequence: UInt8) -> BatteryStatus? {
        guard reply.count > chargingIndex,
              reply[0] == reportID, reply[2] == statusCommand, reply[4] == sequence, reply[5] == replyOK,
              reply[percentIndex] <= 100
        else { return nil }
        return BatteryStatus(percent: Int(reply[percentIndex]), isCharging: reply[chargingIndex] == 1)
    }
}
