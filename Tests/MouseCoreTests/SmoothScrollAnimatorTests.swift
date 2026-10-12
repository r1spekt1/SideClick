import Testing
@testable import MouseCore

private let frame = 1.0 / 128

private func runToIdle(_ animator: inout SmoothScrollAnimator) -> (vertical: Int, horizontal: Int, frames: Int) {
    var vertical = 0, horizontal = 0, frames = 0
    while !animator.isIdle && frames < 1000 {
        let pixels = animator.step(dt: frame)
        vertical += Int(pixels.vertical)
        horizontal += Int(pixels.horizontal)
        frames += 1
    }
    return (vertical, horizontal, frames)
}

@Suite struct SmoothScrollAnimatorTests {
    @Test func idleInitially() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        #expect(animator.isIdle)
        let pixels = animator.step(dt: frame)
        #expect(pixels.vertical == 0 && pixels.horizontal == 0)
    }

    @Test func emitsExactlyTheAddedDistance() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: 120, horizontal: 0))
        let result = runToIdle(&animator)
        #expect(result.vertical == 120)
        #expect(result.horizontal == 0)
    }

    @Test func spreadsDistanceOverSeveralFrames() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: 120, horizontal: 0))
        let first = animator.step(dt: frame)
        #expect(first.vertical > 0 && first.vertical < 120)
    }

    @Test func finishesShortlyAfterDuration() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: 120, horizontal: 0))
        let result = runToIdle(&animator)
        #expect(Double(result.frames) * frame <= 0.25 * 1.5)
    }

    @Test func negativeDirection() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: -120, horizontal: 0))
        #expect(runToIdle(&animator).vertical == -120)
    }

    @Test func reversingDirectionCancelsRemainingMotion() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: 120, horizontal: 0))
        _ = animator.step(dt: frame)
        animator.add(ScrollDelta(vertical: -60, horizontal: 0))
        #expect(runToIdle(&animator).vertical == -60)
    }

    @Test func zeroDurationEmitsEverythingAtOnce() {
        var animator = SmoothScrollAnimator(duration: 0)
        animator.add(ScrollDelta(vertical: 50, horizontal: 0))
        #expect(animator.step(dt: frame).vertical == 50)
        #expect(animator.isIdle)
    }

    @Test func axesAreIndependent() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: 30, horizontal: -45))
        let result = runToIdle(&animator)
        #expect(result.vertical == 30)
        #expect(result.horizontal == -45)
    }

    @Test func resetStopsMotion() {
        var animator = SmoothScrollAnimator(duration: 0.25)
        animator.add(ScrollDelta(vertical: 120, horizontal: 0))
        animator.reset()
        #expect(animator.isIdle)
    }
}
