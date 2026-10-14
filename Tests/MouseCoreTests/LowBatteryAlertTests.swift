import Testing
@testable import MouseCore

/// Feeds the readings to a fresh alert and returns which of them warned. A negative value is a
/// charging reading at that level.
private func warnings(_ levels: [Int]) -> [Bool] {
    var alert = LowBatteryAlert()
    return levels.map { alert.shouldWarn(for: BatteryStatus(percent: abs($0), isCharging: $0 < 0)) }
}

@Suite struct LowBatteryAlertTests {
    @Test func warnsOnceWhenTheLevelDropsToTheThreshold() {
        #expect(warnings([16, 15, 14, 5]) == [false, true, false, false])
    }

    @Test func wobblingBelowTheRearmLevelDoesNotWarnAgain() {
        #expect(warnings([15, 18, 20, 15]) == [true, false, false, false])
    }

    @Test func rearmsAboveTheRearmLevel() {
        #expect(warnings([15, 21, 15]) == [true, false, true])
    }

    @Test func chargingNeverWarnsAndRearms() {
        #expect(warnings([10, -10, 10]) == [true, false, true])
    }

    @Test func lowMeansAtMostTheThresholdAndNotCharging() {
        #expect(BatteryStatus(percent: 15, isCharging: false).isLow)
        #expect(!BatteryStatus(percent: 16, isCharging: false).isLow)
        #expect(!BatteryStatus(percent: 5, isCharging: true).isLow)
    }

    @Test func alreadyLowAtLaunchWarns() {
        #expect(warnings([3]) == [true])
    }
}
