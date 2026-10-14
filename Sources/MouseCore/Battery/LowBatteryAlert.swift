/// Decides when to warn about a low battery: once per discharge, when the level first becomes low
/// (`BatteryStatus.isLow`). It re-arms only after charging or once the level is above `rearmAbove`,
/// so a level that wobbles around the threshold does not warn again.
public struct LowBatteryAlert: Sendable {
    public static let rearmAbove = 20

    private var isArmed = true

    public init() {}

    /// Feed every new reading; returns true when the warning should be shown now.
    public mutating func shouldWarn(for status: BatteryStatus) -> Bool {
        if status.isCharging || status.percent > Self.rearmAbove {
            isArmed = true
            return false
        }
        guard isArmed, status.isLow else { return false }
        isArmed = false
        return true
    }
}
