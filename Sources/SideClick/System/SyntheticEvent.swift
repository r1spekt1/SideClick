import CoreGraphics

/// Marks events we post so our own taps let them through untouched.
enum SyntheticEvent {
    private static let marker: Int64 = 0x584D_4658 // "XMFX"

    static func isOurs(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == marker
    }

    static func post(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: marker)
        event.post(tap: .cghidEventTap)
    }
}
