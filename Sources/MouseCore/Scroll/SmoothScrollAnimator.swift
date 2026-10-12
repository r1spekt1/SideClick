import Foundation

/// Spreads scroll distance over time with an exponential ease-out. Pure: the caller drives
/// it with frame intervals and posts the returned whole-pixel deltas.
public struct SmoothScrollAnimator: Sendable {
    public var duration: TimeInterval

    private var remaining = ScrollDelta.zero
    /// Sub-pixel part of distance already released but not yet posted.
    private var carry = ScrollDelta.zero

    public init(duration: TimeInterval) {
        self.duration = duration
    }

    public var isIdle: Bool { remaining.isZero }

    public mutating func reset() {
        remaining = .zero
        carry = .zero
    }

    /// Adds distance in pixels. Reversing direction drops the old motion instead of fighting it.
    public mutating func add(_ delta: ScrollDelta) {
        if delta.vertical * remaining.vertical < 0 {
            remaining.vertical = 0
            carry.vertical = 0
        }
        if delta.horizontal * remaining.horizontal < 0 {
            remaining.horizontal = 0
            carry.horizontal = 0
        }
        remaining.vertical += delta.vertical
        remaining.horizontal += delta.horizontal
    }

    /// Advances by `dt` seconds and returns the whole pixels to post this frame.
    public mutating func step(dt: TimeInterval) -> (vertical: Int32, horizontal: Int32) {
        let factor = duration > 0 ? 1 - exp(-dt / (duration / 5)) : 1
        let vertical = Self.advance(&remaining.vertical, carry: &carry.vertical, factor: factor)
        let horizontal = Self.advance(&remaining.horizontal, carry: &carry.horizontal, factor: factor)
        return (vertical, horizontal)
    }

    private static func advance(_ remaining: inout Double, carry: inout Double, factor: Double) -> Int32 {
        var move = remaining * factor
        // Finish instead of crawling through the last sub-pixel tail.
        if abs(remaining - move) < 0.5 { move = remaining }
        remaining -= move
        let total = move + carry
        let whole = remaining == 0 ? total.rounded() : total.rounded(.towardZero)
        carry = remaining == 0 ? 0 : total - whole
        return Int32(whole)
    }
}
