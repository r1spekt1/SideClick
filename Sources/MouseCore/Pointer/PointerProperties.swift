/// HID service property values (IOFixed 16.16) for one mouse's pointer.
public struct PointerProperties: Equatable, Sendable {
    public static let accelerationKey = "HIDMouseAcceleration"
    public static let resolutionKey = "HIDPointerResolution"
    /// Resolution macOS assumes for mice that report none: 400 dpi.
    public static let defaultResolution = fixed(400)

    /// Acceleration curve value; -1 means linear (acceleration off).
    public let acceleration: Int
    /// Pointer resolution; lower values move the pointer faster.
    public let resolution: Int

    /// `nativeResolution` is what the mouse reported before we changed anything (IOFixed), so a
    /// speed of 1 keeps every mouse's own feel. Zero or negative falls back to `defaultResolution`.
    public init(settings: PointerSettings, nativeResolution: Int = PointerProperties.defaultResolution) {
        acceleration = settings.accelerationEnabled ? Self.fixed(min(max(settings.acceleration, 0), 3)) : -1
        let speed = min(max(settings.speed, 0.25), 4)
        let native = nativeResolution > 0 ? nativeResolution : Self.defaultResolution
        resolution = Int((Double(native) / speed).rounded())
    }

    private static func fixed(_ value: Double) -> Int {
        Int((value * 65536).rounded())
    }
}
