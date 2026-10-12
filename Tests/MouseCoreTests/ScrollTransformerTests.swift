import Testing
@testable import MouseCore

private func settings(_ configure: (inout ScrollSettings) -> Void = { _ in }) -> ScrollSettings {
    var settings = ScrollSettings()
    configure(&settings)
    return settings
}

@Suite struct ScrollTransformerTests {
    @Test func defaultsLeaveScrollUntouched() {
        let delta = ScrollDelta(vertical: 3, horizontal: -1)
        #expect(ScrollTransformer.transform(delta, settings: settings(), shiftHeld: false) == delta)
    }

    @Test func invertFlipsBothAxes() {
        let result = ScrollTransformer.transform(ScrollDelta(vertical: 3, horizontal: -1),
                                                 settings: settings { $0.inverted = true }, shiftHeld: false)
        #expect(result == ScrollDelta(vertical: -3, horizontal: 1))
    }

    @Test func multiplierScales() {
        let result = ScrollTransformer.transform(ScrollDelta(vertical: 3, horizontal: 0),
                                                 settings: settings { $0.lineMultiplier = 2 }, shiftHeld: false)
        #expect(result == ScrollDelta(vertical: 6, horizontal: 0))
    }

    @Test func shiftMovesVerticalToHorizontal() {
        let result = ScrollTransformer.transform(ScrollDelta(vertical: 3, horizontal: 0),
                                                 settings: settings(), shiftHeld: true)
        #expect(result == ScrollDelta(vertical: 0, horizontal: 3))
    }

    @Test func shiftIgnoredWhenDisabled() {
        let result = ScrollTransformer.transform(ScrollDelta(vertical: 3, horizontal: 0),
                                                 settings: settings { $0.shiftScrollsHorizontally = false },
                                                 shiftHeld: true)
        #expect(result == ScrollDelta(vertical: 3, horizontal: 0))
    }

    @Test func shiftKeepsAlreadyHorizontalScroll() {
        let result = ScrollTransformer.transform(ScrollDelta(vertical: 0, horizontal: 2),
                                                 settings: settings(), shiftHeld: true)
        #expect(result == ScrollDelta(vertical: 0, horizontal: 2))
    }

    @Test func combinedShiftInvertAndMultiplier() {
        let result = ScrollTransformer.transform(ScrollDelta(vertical: 2, horizontal: 0),
                                                 settings: settings { $0.inverted = true; $0.lineMultiplier = 1.5 },
                                                 shiftHeld: true)
        #expect(result == ScrollDelta(vertical: 0, horizontal: -3))
    }

    @Test(arguments: [(0.0, Int64(0)), (0.25, 1), (-0.25, -1), (1.5, 2), (-2.25, -2), (2.5, 3)])
    func wholeLinesNeverDropsANotch(value: Double, expected: Int64) {
        #expect(ScrollTransformer.wholeLines(value) == expected)
    }
}
