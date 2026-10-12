import Foundation

public struct RecognizedGesture: Equatable, Sendable {
    public let button: SideButton
    public let gesture: Gesture

    public init(button: SideButton, gesture: Gesture) {
        self.button = button
        self.gesture = gesture
    }
}

/// Turns side-button presses into gestures. Pure: the caller owns the clock and must call
/// `tick(at:)` once `nextDeadline` has passed.
public struct GestureRecognizer: Sendable {
    public var timing: GestureTiming
    public var mappedGestures: [SideButton: Set<Gesture>]

    private struct ButtonState: Sendable {
        var isDown = false
        var downAt: TimeInterval = 0
        var lastUpAt: TimeInterval = 0
        var clickCount = 0
        var longPressFired = false
    }

    private var states: [SideButton: ButtonState] = [:]

    public init(timing: GestureTiming = GestureTiming(), mappedGestures: [SideButton: Set<Gesture>] = [:]) {
        self.timing = timing
        self.mappedGestures = mappedGestures
    }

    public var nextDeadline: TimeInterval? {
        SideButton.allCases.compactMap { deadline(for: $0) }.min()
    }

    public mutating func reset() {
        states = [:]
    }

    public mutating func buttonDown(_ button: SideButton, at time: TimeInterval) -> [RecognizedGesture] {
        let output = tick(at: time)
        var state = states[button, default: ButtonState()]
        state.isDown = true
        state.downAt = time
        state.longPressFired = false
        states[button] = state
        return output
    }

    public mutating func buttonUp(_ button: SideButton, at time: TimeInterval) -> [RecognizedGesture] {
        var output = tick(at: time)
        guard var state = states[button], state.isDown else { return output }
        state.isDown = false
        if state.longPressFired {
            state.clickCount = 0
        } else {
            state.clickCount += 1
            state.lastUpAt = time
            if state.clickCount >= maxClickCount(for: button) {
                output += recognized(clicks: state.clickCount, on: button)
                state.clickCount = 0
            }
        }
        states[button] = state
        return output
    }

    public mutating func tick(at time: TimeInterval) -> [RecognizedGesture] {
        var output: [RecognizedGesture] = []
        for button in SideButton.allCases {
            guard var state = states[button] else { continue }
            if state.isDown {
                if !state.longPressFired, isMapped(.longPress, on: button),
                   time >= state.downAt + timing.longPressThreshold {
                    state.longPressFired = true
                    state.clickCount = 0
                    output.append(RecognizedGesture(button: button, gesture: .longPress))
                }
            } else if state.clickCount > 0, time >= state.lastUpAt + timing.multiClickWindow {
                output += recognized(clicks: state.clickCount, on: button)
                state.clickCount = 0
            }
            states[button] = state
        }
        return output
    }

    private func deadline(for button: SideButton) -> TimeInterval? {
        guard let state = states[button] else { return nil }
        if state.isDown {
            guard !state.longPressFired, isMapped(.longPress, on: button) else { return nil }
            return state.downAt + timing.longPressThreshold
        }
        return state.clickCount > 0 ? state.lastUpAt + timing.multiClickWindow : nil
    }

    private func isMapped(_ gesture: Gesture, on button: SideButton) -> Bool {
        mappedGestures[button]?.contains(gesture) ?? false
    }

    private func maxClickCount(for button: SideButton) -> Int {
        mappedGestures[button]?.compactMap(\.clickCount).max() ?? 0
    }

    private func recognized(clicks: Int, on button: SideButton) -> [RecognizedGesture] {
        guard let gesture = Gesture(clickCount: clicks), isMapped(gesture, on: button) else { return [] }
        return [RecognizedGesture(button: button, gesture: gesture)]
    }
}
