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

    public init(vendorID: Int, productID: Int, productName: String,
                primaryUsagePage: Int, primaryUsage: Int, isBuiltIn: Bool) {
        self.vendorID = vendorID
        self.productID = productID
        self.productName = productName
        self.primaryUsagePage = primaryUsagePage
        self.primaryUsage = primaryUsage
        self.isBuiltIn = isBuiltIn
    }

    /// A mouse (Generic Desktop / Mouse) that is not built in and not a trackpad. The name check
    /// is defensive: an external trackpad that also reports a mouse usage must stay untouched.
    public var isExternalMouse: Bool {
        primaryUsagePage == Self.genericDesktopPage
            && primaryUsage == Self.mouseUsage
            && !isBuiltIn
            && !productName.localizedCaseInsensitiveContains("trackpad")
    }

    /// Identifies a device model, e.g. "10007:20499". Two identical mice share it.
    public var key: String { "\(vendorID):\(productID)" }
}
