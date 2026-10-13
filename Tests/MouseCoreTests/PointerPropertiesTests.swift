import Testing
@testable import MouseCore

private func settings(_ configure: (inout PointerSettings) -> Void = { _ in }) -> PointerSettings {
    var settings = PointerSettings()
    configure(&settings)
    return settings
}

@Suite struct PointerPropertiesTests {
    @Test func defaultIsUnitAcceleration() {
        #expect(PointerProperties(settings: settings()).acceleration == 65536)
    }

    @Test func disabledAccelerationIsLinear() {
        #expect(PointerProperties(settings: settings { $0.accelerationEnabled = false }).acceleration == -1)
    }

    @Test func accelerationIsClamped() {
        #expect(PointerProperties(settings: settings { $0.acceleration = 5 }).acceleration == 3 * 65536)
        #expect(PointerProperties(settings: settings { $0.acceleration = -1 }).acceleration == 0)
    }

    @Test func accelerationIsWrittenLastSoTheResolutionTakesEffect() {
        let values = [PointerProperties.accelerationKey: 65536, PointerProperties.resolutionKey: 200 * 65536]
        #expect(PointerProperties.writeOrder(values).map(\.key)
                == [PointerProperties.resolutionKey, PointerProperties.accelerationKey])
    }
}
