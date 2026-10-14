public struct BatteryStatus: Equatable, Sendable {
    /// 0...100. While charging the mouse reports 100 instead of the real level.
    public var percent: Int
    public var isCharging: Bool

    public init(percent: Int, isCharging: Bool) {
        self.percent = percent
        self.isCharging = isCharging
    }

    public static let lowThreshold = 15

    public var isLow: Bool { !isCharging && percent <= Self.lowThreshold }
}
