/// The standard Bluetooth Battery Service (0x180F): its Battery Level characteristic (0x2A19) is
/// one byte, the percent. It says nothing about charging.
public enum BluetoothBattery {
    public static let serviceUUID = "180F"
    public static let levelUUID = "2A19"

    public static func status(fromLevel value: [UInt8]) -> BatteryStatus? {
        guard let level = value.first, level <= 100 else { return nil }
        return BatteryStatus(percent: Int(level), isCharging: false)
    }

    /// Which reading to show when both sources may have one. A Bluetooth reading exists only while
    /// a mouse is live on Bluetooth, so it wins. The receiver answers from its own cache, so while
    /// its mouse is on Bluetooth it keeps returning the level from its last 2.4 GHz session. Its
    /// HID presence can't tell this apart, since the plugged-in receiver still enumerates.
    public static func preferred(receiver: BatteryStatus?, bluetooth: BatteryStatus?) -> BatteryStatus? {
        bluetooth ?? receiver
    }
}
