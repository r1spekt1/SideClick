import CoreGraphics
import Foundation
import MouseCore

/// Intercepts mapped side buttons, feeds the gesture recognizer and runs the mapped actions.
/// Unmapped buttons pass through untouched.
@MainActor
final class ButtonController {
    /// Called on every physical press (true) and release (false); drives the UI indicator.
    var onButtonActivity: ((SideButton, Bool) -> Void)?

    private var recognizer = GestureRecognizer()
    private var mappings: [SideButton: ButtonMapping] = [:]
    private var timer: Timer?
    /// Buttons currently down, as reported through onButtonActivity.
    private var heldButtons: Set<SideButton> = []
    /// Mapped buttons whose down we swallowed; only their up/drag is swallowed or rewritten.
    private var swallowedDown: Set<SideButton> = []
    private lazy var tap = EventTap(events: [.otherMouseDown, .otherMouseUp, .otherMouseDragged],
                                    onDisabled: { [weak self] in
        MainActor.assumeIsolated { self?.resetPressState() }
    }) { [weak self] type, event in
        MainActor.assumeIsolated {
            // nil from handle() means "swallow", so it must not fall back to `event`.
            guard let self else { return event }
            return self.handle(type, event)
        }
    }

    func update(settings: AppSettings) {
        mappings = [.back: settings.backButton, .forward: settings.forwardButton]
        recognizer.timing = settings.timing
        recognizer.mappedGestures = mappings.mapValues(\.mappedGestures)
        resetPressState()
    }

    func start() -> Bool { tap.start() }

    func stop() {
        tap.stop()
        resetPressState()
    }

    /// Forgets presses in flight (their up may never reach us) and reports held buttons released.
    private func resetPressState() {
        recognizer.reset()
        swallowedDown.removeAll()
        for button in heldButtons { onButtonActivity?(button, false) }
        heldButtons.removeAll()
        rescheduleTimer()
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> CGEvent? {
        guard !SyntheticEvent.isOurs(event),
              let button = SideButton(cgButtonNumber: event.getIntegerValueField(.mouseEventButtonNumber))
        else { return event }

        if type == .otherMouseDown {
            heldButtons.insert(button)
            onButtonActivity?(button, true)
        }
        if type == .otherMouseUp {
            heldButtons.remove(button)
            onButtonActivity?(button, false)
        }
        guard let mapping = mappings[button], !mapping.mappedGestures.isEmpty else { return event }

        let now = ProcessInfo.processInfo.systemUptime
        switch type {
        case .otherMouseDown:
            swallowedDown.insert(button)
            perform(recognizer.buttonDown(button, at: now))
        case .otherMouseUp:
            // An up whose down was not swallowed belongs to the app, which saw that down.
            guard swallowedDown.remove(button) != nil else { return event }
            perform(recognizer.buttonUp(button, at: now))
        default:
            guard swallowedDown.contains(button) else { return event }
            // Moving while a mapped button is held: keep the cursor moving.
            event.type = .mouseMoved
            return event
        }
        rescheduleTimer()
        return nil
    }

    private func perform(_ gestures: [RecognizedGesture]) {
        for gesture in gestures {
            if let action = mappings[gesture.button]?[gesture.gesture] {
                ActionExecutor.perform(action)
            }
        }
    }

    private func rescheduleTimer() {
        timer?.invalidate()
        timer = nil
        guard let deadline = recognizer.nextDeadline else { return }
        let delay = max(0, deadline - ProcessInfo.processInfo.systemUptime)
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.perform(self.recognizer.tick(at: ProcessInfo.processInfo.systemUptime))
                self.rescheduleTimer()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
