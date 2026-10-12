import CoreGraphics
import Foundation
import MouseCore

/// Rewrites mouse-wheel events (non-continuous) and optionally replaces them with smooth
/// pixel scrolling. Trackpad (continuous) events pass through untouched.
@MainActor
final class ScrollController {
    private var settings = ScrollSettings()
    private var animator = SmoothScrollAnimator(duration: ScrollSettings().smoothDuration)
    private var frameTimer: Timer?
    private var lastFrameTime: TimeInterval = 0
    private lazy var tap = EventTap(events: [.scrollWheel]) { [weak self] _, event in
        MainActor.assumeIsolated {
            // nil from handle() means "swallow", so it must not fall back to `event`.
            guard let self else { return event }
            return self.handle(event)
        }
    }

    func update(settings: ScrollSettings) {
        self.settings = settings
        animator.duration = settings.smoothDuration
    }

    func start() -> Bool { tap.start() }

    func stop() {
        tap.stop()
        stopGliding()
    }

    private func handle(_ event: CGEvent) -> CGEvent? {
        guard !SyntheticEvent.isOurs(event),
              event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 else { return event }
        let shiftHeld = event.flags.contains(.maskShift)
        // Synthetic pixel events carry no modifier flags, so modifier+wheel (e.g. zoom) must stay on the in-place path.
        let hasPassThroughModifier = !event.flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate])

        if settings.smoothEnabled && !hasPassThroughModifier {
            let notches = ScrollDelta(vertical: Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1)),
                                      horizontal: Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2)))
            let lines = ScrollTransformer.transform(notches, settings: settings, shiftHeld: shiftHeld)
            animator.add(ScrollDelta(vertical: lines.vertical * settings.smoothPixelsPerLine,
                                     horizontal: lines.horizontal * settings.smoothPixelsPerLine))
            startGliding()
            return nil
        }

        let lines = transformed(event, .scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2, shiftHeld)
        let fixed = transformed(event, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2, shiftHeld)
        let points = transformed(event, .scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2, shiftHeld)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: ScrollTransformer.wholeLines(lines.vertical))
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: ScrollTransformer.wholeLines(lines.horizontal))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: fixed.vertical)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixed.horizontal)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: Int64(points.vertical.rounded()))
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: Int64(points.horizontal.rounded()))
        // Axes already swapped; drop Shift so apps do not swap them back.
        if shiftHeld && settings.shiftScrollsHorizontally { event.flags.remove(.maskShift) }
        return event
    }

    private func transformed(_ event: CGEvent, _ vertical: CGEventField, _ horizontal: CGEventField,
                             _ shiftHeld: Bool) -> ScrollDelta {
        let raw = ScrollDelta(vertical: event.getDoubleValueField(vertical),
                              horizontal: event.getDoubleValueField(horizontal))
        return ScrollTransformer.transform(raw, settings: settings, shiftHeld: shiftHeld)
    }

    private func startGliding() {
        guard frameTimer == nil else { return }
        lastFrameTime = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.frame() }
        }
        RunLoop.main.add(timer, forMode: .common)
        frameTimer = timer
    }

    private func frame() {
        let now = ProcessInfo.processInfo.systemUptime
        let pixels = animator.step(dt: now - lastFrameTime)
        lastFrameTime = now
        if pixels.vertical != 0 || pixels.horizontal != 0 {
            postPixelScroll(vertical: pixels.vertical, horizontal: pixels.horizontal)
        }
        if animator.isIdle { stopGliding() }
    }

    private func stopGliding() {
        animator.reset()
        frameTimer?.invalidate()
        frameTimer = nil
    }

    /// Posts precise (continuous) pixel deltas without a gesture phase: a phase would make
    /// AppKit treat the glide as a trackpad gesture and rubber-band past the content edges.
    private func postPixelScroll(vertical: Int32, horizontal: Int32) {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
                                  wheel1: vertical, wheel2: horizontal, wheel3: 0) else { return }
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        SyntheticEvent.post(event)
    }
}
