/// A scroll amount on both axes in CGEvent convention (positive vertical = scroll up).
public struct ScrollDelta: Equatable, Sendable {
    public var vertical: Double
    public var horizontal: Double

    public init(vertical: Double, horizontal: Double) {
        self.vertical = vertical
        self.horizontal = horizontal
    }

    public static let zero = ScrollDelta(vertical: 0, horizontal: 0)
    public var isZero: Bool { vertical == 0 && horizontal == 0 }
}

public enum ScrollTransformer {
    /// Applies Shift-to-horizontal, invert and the notch multiplier, in that order.
    public static func transform(_ delta: ScrollDelta, settings: ScrollSettings, shiftHeld: Bool) -> ScrollDelta {
        var delta = delta
        if shiftHeld, settings.shiftScrollsHorizontally, delta.horizontal == 0 {
            delta = ScrollDelta(vertical: 0, horizontal: delta.vertical)
        }
        let factor = (settings.inverted ? -1 : 1) * settings.lineMultiplier
        return ScrollDelta(vertical: delta.vertical * factor, horizontal: delta.horizontal * factor)
    }

    /// Rounds a scaled line delta without letting a non-zero notch collapse to zero.
    public static func wholeLines(_ value: Double) -> Int64 {
        guard value != 0 else { return 0 }
        let rounded = value.rounded()
        if rounded == 0 { return value > 0 ? 1 : -1 }
        return Int64(rounded)
    }
}
