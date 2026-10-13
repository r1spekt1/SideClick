import Testing
@testable import MouseCore

private func info(page: Int = 1, usage: Int = 2, name: String = "Mi Wireless Mouse",
                  builtIn: Bool = false) -> HIDDeviceInfo {
    HIDDeviceInfo(vendorID: 10007, productID: 20499, productName: name,
                  primaryUsagePage: page, primaryUsage: usage, isBuiltIn: builtIn)
}

@Suite struct HIDDeviceInfoTests {
    @Test func externalMouseIsAccepted() {
        #expect(info().isExternalMouse)
    }

    @Test func keyboardUsageIsRejected() {
        #expect(!info(usage: 6).isExternalMouse)
    }

    @Test func nonDesktopUsagePageIsRejected() {
        #expect(!info(page: 13, usage: 12).isExternalMouse)
        #expect(!info(page: 65280, usage: 11).isExternalMouse)
    }

    @Test func builtInDeviceIsRejected() {
        #expect(!info(builtIn: true).isExternalMouse)
    }

    @Test func trackpadByNameIsRejected() {
        #expect(!info(name: "Magic Trackpad").isExternalMouse)
        #expect(!info(name: "magic trackpad 2").isExternalMouse)
        #expect(!info(name: "Apple Internal Keyboard / Trackpad").isExternalMouse)
    }

    @Test func keyCombinesVendorAndProductInDecimal() {
        #expect(info().key == "10007:20499")
    }
}
