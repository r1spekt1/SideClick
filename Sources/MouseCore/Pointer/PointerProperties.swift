/// HID service property values (IOFixed 16.16) for one mouse's pointer.
public struct PointerProperties: Equatable, Sendable {
    /// The value behind System Settings → Mouse → Tracking speed.
    public static let accelerationKey = "HIDMouseAcceleration"
    /// Written by the Speed slider of earlier versions; now only ever restored.
    public static let resolutionKey = "HIDPointerResolution"

    /// Acceleration curve value; -1 means linear (acceleration off).
    public let acceleration: Int

    public init(settings: PointerSettings) {
        acceleration = settings.accelerationEnabled ? Self.fixed(min(max(settings.acceleration, 0), 3)) : -1
    }

    /// hidd reads the resolution only while it rebuilds the acceleration curve, which a change of
    /// `accelerationKey` triggers and a change of `resolutionKey` does not. So the acceleration goes
    /// last, after everything the curve depends on.
    public static func writeOrder(_ values: [String: Int]) -> [(key: String, value: Int)] {
        values.sorted { $0.key != accelerationKey && ($1.key == accelerationKey || $0.key < $1.key) }
            .map { (key: $0.key, value: $0.value) }
    }

    private static func fixed(_ value: Double) -> Int {
        Int((value * 65536).rounded())
    }
}
