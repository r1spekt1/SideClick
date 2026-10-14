/// The standard Bluetooth Battery Service (0x180F): its Battery Level characteristic (0x2A19) is
/// one byte, the percent. It says nothing about charging.
public enum BluetoothBattery {
    public static let serviceUUID = "180F"
    public static let levelUUID = "2A19"

    public static func status(fromLevel value: [UInt8]) -> BatteryStatus? {
        guard let level = value.first, level <= 100 else { return nil }
        return BatteryStatus(percent: Int(level), isCharging: false)
    }
}
