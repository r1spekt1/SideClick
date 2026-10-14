import Testing
@testable import MouseCore

private func info(vendor: Int = 10007, product: Int = 20499, transport: String) -> HIDDeviceInfo {
    HIDDeviceInfo(vendorID: vendor, productID: product, productName: "Mouse",
                  primaryUsagePage: 1, primaryUsage: 2, isBuiltIn: false, transport: transport)
}

@Suite struct MouseConnectionTests {
    @Test func classicBluetoothAndLowEnergyAreToldApart() {
        #expect(info(transport: "Bluetooth").connection == .bluetooth)
        #expect(info(transport: "Bluetooth Low Energy").connection == .bluetoothLE)
    }

    /// What macOS 27 reports for a Bluetooth LE mouse differs from the spelling in IOHIDKeys.h.
    @Test func bothLowEnergySpellingsAreLowEnergy() {
        #expect(info(transport: "BluetoothLowEnergy").connection == .bluetoothLE)
    }

    @Test func whiteSharkReceiverIs24GHz() {
        #expect(info(vendor: 0x248A, product: 0x5B2F, transport: "USB").connection == .receiver)
    }

    @Test func whiteSharkOnItsCableIsWired() {
        #expect(info(vendor: 0x248A, product: 0x5B2E, transport: "USB").connection == .wired)
    }

    @Test func otherUSBMiceAreUSB() {
        #expect(info(transport: "USB").connection == .usb)
        #expect(info(vendor: 0x248A, product: 0x1234, transport: "USB").connection == .usb)
    }

    @Test func unknownTransportHasNoConnection() {
        #expect(info(transport: "").connection == nil)
        #expect(info(transport: "Virtual").connection == nil)
    }

    /// A receiver still lists its mouse while that mouse is on Bluetooth; the menu shows `first`.
    @Test func liveLinkSortsBeforeTheReceiverWithTheSameName() {
        let receiver = ConnectedMouse(name: "MAXIMUS", connection: .receiver)
        let bluetooth = ConnectedMouse(name: "MAXIMUS", connection: .bluetoothLE)
        let wired = ConnectedMouse(name: "MAXIMUS", connection: .wired)
        let other = ConnectedMouse(name: "Alpha", connection: .usb)
        let expected = [other, wired, bluetooth, receiver]
        #expect(ConnectedMouse.sorted([receiver, bluetooth, other, wired]) == expected)
        #expect(ConnectedMouse.sorted([wired, other, bluetooth, receiver]) == expected)
    }
}

@Suite struct BluetoothBatteryTests {
    @Test func levelByteIsThePercent() {
        #expect(BluetoothBattery.status(fromLevel: [69]) == BatteryStatus(percent: 69, isCharging: false))
        #expect(BluetoothBattery.status(fromLevel: [0]) == BatteryStatus(percent: 0, isCharging: false))
        #expect(BluetoothBattery.status(fromLevel: [100]) == BatteryStatus(percent: 100, isCharging: false))
    }

    @Test func emptyOrImpossibleLevelIsRejected() {
        #expect(BluetoothBattery.status(fromLevel: []) == nil)
        #expect(BluetoothBattery.status(fromLevel: [101]) == nil)
        #expect(BluetoothBattery.status(fromLevel: [255]) == nil)
    }

    @Test func liveBluetoothReadingWinsOverTheReceiverCache() {
        let receiver = BatteryStatus(percent: 80, isCharging: false)
        let bluetooth = BatteryStatus(percent: 40, isCharging: false)
        #expect(BluetoothBattery.preferred(receiver: receiver, bluetooth: bluetooth) == bluetooth)
        #expect(BluetoothBattery.preferred(receiver: receiver, bluetooth: nil) == receiver)
        #expect(BluetoothBattery.preferred(receiver: nil, bluetooth: bluetooth) == bluetooth)
        #expect(BluetoothBattery.preferred(receiver: nil, bluetooth: nil) == nil)
    }
}
