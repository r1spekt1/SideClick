import Foundation

/// The HID properties that decide whether a device is an external mouse. Plain data, so the
/// decision can be tested without hardware; the app target fills it from IOKit.
public struct HIDDeviceInfo: Equatable, Sendable {
    public static let genericDesktopPage = 1
    public static let mouseUsage = 2

    public var vendorID: Int
    public var productID: Int
    public var productName: String
    public var primaryUsagePage: Int
    public var primaryUsage: Int
    public var isBuiltIn: Bool
    /// The HID transport, e.g. "USB", "Bluetooth" or "Bluetooth Low Energy".
    public var transport: String

    public init(vendorID: Int, productID: Int, productName: String,
                primaryUsagePage: Int, primaryUsage: Int, isBuiltIn: Bool, transport: String = "") {
        self.vendorID = vendorID
        self.productID = productID
        self.productName = productName
        self.primaryUsagePage = primaryUsagePage
        self.primaryUsage = primaryUsage
        self.isBuiltIn = isBuiltIn
        self.transport = transport
    }

    /// A mouse (Generic Desktop / Mouse) that is not built in and not a trackpad. The name check
    /// is defensive: an external trackpad that also reports a mouse usage must stay untouched.
    public var isExternalMouse: Bool {
        primaryUsagePage == Self.genericDesktopPage
            && primaryUsage == Self.mouseUsage
            && !isBuiltIn
            && !productName.localizedCaseInsensitiveContains("trackpad")
    }

    /// How the mouse is connected, or nil for an unknown transport (e.g. a virtual device).
    /// A USB receiver and a USB cable look the same, so only known models get `.receiver`/`.wired`.
    public var connection: MouseConnection? {
        // macOS 27 reports "Bluetooth Low Energy"; IOHIDKeys.h spells it "BluetoothLowEnergy".
        if ["Bluetooth Low Energy", "BluetoothLowEnergy"].contains(transport) { return .bluetoothLE }
        if transport.hasPrefix("Bluetooth") { return .bluetooth }
        guard transport == "USB" else { return nil }
        guard vendorID == WhiteSharkReceiver.vendorID else { return .usb }
        switch productID {
        case WhiteSharkReceiver.productID: return .receiver
        case WhiteSharkReceiver.wiredMouseProductID: return .wired
        default: return .usb
        }
    }

    /// Identifies a device model, e.g. "10007:20499". Two identical mice share it.
    public var key: String { "\(vendorID):\(productID)" }
}
