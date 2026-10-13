import Testing
@testable import MouseCore

private func settings(_ configure: (inout PointerSettings) -> Void = { _ in }) -> PointerSettings {
    var settings = PointerSettings()
    configure(&settings)
    return settings
}

@Suite struct PointerPropertiesTests {
    @Test func defaultsAreNativeResolutionAndUnitAcceleration() {
        let props = PointerProperties(settings: settings())
        #expect(props.acceleration == 65536)
        #expect(props.resolution == 400 * 65536)
        #expect(PointerProperties.defaultResolution == 400 * 65536)
    }

    @Test func disabledAccelerationIsLinear() {
        #expect(PointerProperties(settings: settings { $0.accelerationEnabled = false }).acceleration == -1)
    }

    @Test func fasterSpeedLowersResolution() {
        #expect(PointerProperties(settings: settings { $0.speed = 2 }).resolution == 200 * 65536)
    }

    @Test func valuesAreClamped() {
        #expect(PointerProperties(settings: settings { $0.speed = 10 }).resolution == 100 * 65536)
        #expect(PointerProperties(settings: settings { $0.speed = 0 }).resolution == 1600 * 65536)
        #expect(PointerProperties(settings: settings { $0.acceleration = 5 }).acceleration == 3 * 65536)
        #expect(PointerProperties(settings: settings { $0.acceleration = -1 }).acceleration == 0)
    }

    @Test func speedIsRelativeToTheDevicesNativeResolution() {
        let native = 800 * 65536
        #expect(PointerProperties(settings: settings(), nativeResolution: native).resolution == native)
        #expect(PointerProperties(settings: settings { $0.speed = 2 }, nativeResolution: native).resolution == 400 * 65536)
    }

    @Test func missingNativeResolutionFallsBackToTheDefault() {
        #expect(PointerProperties(settings: settings { $0.speed = 2 }, nativeResolution: 0).resolution == 200 * 65536)
        #expect(PointerProperties(settings: settings { $0.speed = 2 }, nativeResolution: -5).resolution == 200 * 65536)
    }

    @Test func speedIsStillClampedWithANativeResolution() {
        let native = 800 * 65536
        #expect(PointerProperties(settings: settings { $0.speed = 10 }, nativeResolution: native).resolution == 200 * 65536)
        #expect(PointerProperties(settings: settings { $0.speed = 0 }, nativeResolution: native).resolution == 3200 * 65536)
    }
}
