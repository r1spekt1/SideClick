/// HID service property values (IOFixed 16.16) for the Xiaomi pointer.
public struct PointerProperties: Equatable, Sendable {
    public static let accelerationKey = "HIDMouseAcceleration"
    public static let resolutionKey = "HIDPointerResolution"
    /// Resolution macOS assumes for mice that report none: 400 dpi.
    public static let defaultResolution = fixed(400)

    /// Acceleration curve value; -1 means linear (acceleration off).
    public let acceleration: Int
    /// Pointer resolution; lower values move the pointer faster.
    public let resolution: Int

    public init(settings: PointerSettings) {
        acceleration = settings.accelerationEnabled ? Self.fixed(min(max(settings.acceleration, 0), 3)) : -1
        let speed = min(max(settings.speed, 0.25), 4)
        resolution = Self.fixed(400 / speed)
    }

    private static func fixed(_ value: Double) -> Int {
        Int((value * 65536).rounded())
    }
}
