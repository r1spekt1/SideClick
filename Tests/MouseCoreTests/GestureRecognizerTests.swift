import Testing
@testable import MouseCore

private let timing = GestureTiming(multiClickWindow: 0.25, longPressThreshold: 0.5)

private func recognizer(_ back: Set<Gesture>, forward: Set<Gesture> = []) -> GestureRecognizer {
    GestureRecognizer(timing: timing, mappedGestures: [.back: back, .forward: forward])
}

private func g(_ gesture: Gesture, _ button: SideButton = .back) -> RecognizedGesture {
    RecognizedGesture(button: button, gesture: gesture)
}

@Suite struct GestureRecognizerTests {
    @Test func singleOnlyFiresImmediatelyOnRelease() {
        var r = recognizer([.single])
        #expect(r.buttonDown(.back, at: 0) == [])
        #expect(r.buttonUp(.back, at: 0.125) == [g(.single)])
        #expect(r.nextDeadline == nil)
    }

    @Test func singleWaitsForWindowWhenDoubleIsMapped() {
        var r = recognizer([.single, .double])
        _ = r.buttonDown(.back, at: 0)
        #expect(r.buttonUp(.back, at: 0.125) == [])
        #expect(r.nextDeadline == 0.375)
        #expect(r.tick(at: 0.25) == [])
        #expect(r.tick(at: 0.375) == [g(.single)])
        #expect(r.nextDeadline == nil)
    }

    @Test func doubleFiresOnSecondReleaseWithoutWaitingForTriple() {
        var r = recognizer([.single, .double])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.125)
        _ = r.buttonDown(.back, at: 0.25)
        #expect(r.buttonUp(.back, at: 0.375) == [g(.double)])
        #expect(r.nextDeadline == nil)
    }

    @Test func tripleFiresOnThirdRelease() {
        var r = recognizer([.single, .double, .triple])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.0625)
        _ = r.buttonDown(.back, at: 0.125)
        _ = r.buttonUp(.back, at: 0.1875)
        _ = r.buttonDown(.back, at: 0.25)
        #expect(r.buttonUp(.back, at: 0.3125) == [g(.triple)])
    }

    @Test func doubleWaitsForWindowWhenTripleIsMapped() {
        var r = recognizer([.single, .double, .triple])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.0625)
        _ = r.buttonDown(.back, at: 0.125)
        #expect(r.buttonUp(.back, at: 0.1875) == [])
        #expect(r.nextDeadline == 0.4375)
        #expect(r.tick(at: 0.4375) == [g(.double)])
    }

    @Test func longPressFiresWhileHeldAndReleaseIsSilent() {
        var r = recognizer([.single, .longPress])
        _ = r.buttonDown(.back, at: 0)
        #expect(r.nextDeadline == 0.5)
        #expect(r.tick(at: 0.25) == [])
        #expect(r.tick(at: 0.5) == [g(.longPress)])
        #expect(r.buttonUp(.back, at: 0.75) == [])
        #expect(r.nextDeadline == nil)
    }

    @Test func shortClickWithLongPressMappedIsSingle() {
        var r = recognizer([.single, .longPress])
        _ = r.buttonDown(.back, at: 0)
        #expect(r.buttonUp(.back, at: 0.125) == [g(.single)])
    }

    @Test func longPressDiscardsPendingClicks() {
        var r = recognizer([.single, .double, .longPress])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.125)
        _ = r.buttonDown(.back, at: 0.25)
        #expect(r.tick(at: 0.75) == [g(.longPress)])
        #expect(r.buttonUp(.back, at: 1) == [])
        #expect(r.nextDeadline == nil)
    }

    @Test func slowSecondClickCountsAsTwoSingles() {
        var r = recognizer([.single, .double])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.125)
        #expect(r.buttonDown(.back, at: 0.5) == [g(.single)])
        #expect(r.buttonUp(.back, at: 0.625) == [])
        #expect(r.tick(at: 0.875) == [g(.single)])
    }

    @Test func unmappedClickCountEmitsNothing() {
        var r = recognizer([.single, .triple])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.0625)
        _ = r.buttonDown(.back, at: 0.125)
        _ = r.buttonUp(.back, at: 0.1875)
        #expect(r.tick(at: 0.4375) == [])
        #expect(r.nextDeadline == nil)
    }

    @Test func holdWithoutLongPressMappedIsStillAClick() {
        var r = recognizer([.single])
        _ = r.buttonDown(.back, at: 0)
        #expect(r.nextDeadline == nil)
        #expect(r.buttonUp(.back, at: 2) == [g(.single)])
    }

    @Test func buttonsAreIndependent() {
        var r = recognizer([.single], forward: [.single, .double])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonDown(.forward, at: 0.0625)
        #expect(r.buttonUp(.back, at: 0.125) == [g(.single, .back)])
        #expect(r.buttonUp(.forward, at: 0.1875) == [])
        #expect(r.tick(at: 0.4375) == [g(.single, .forward)])
    }

    @Test func nothingMappedEmitsNothing() {
        var r = recognizer([])
        #expect(r.buttonDown(.back, at: 0) == [])
        #expect(r.buttonUp(.back, at: 0.125) == [])
        #expect(r.nextDeadline == nil)
    }

    @Test func resetClearsPendingClicks() {
        var r = recognizer([.single, .double])
        _ = r.buttonDown(.back, at: 0)
        _ = r.buttonUp(.back, at: 0.125)
        r.reset()
        #expect(r.nextDeadline == nil)
        #expect(r.tick(at: 1) == [])
    }
}
