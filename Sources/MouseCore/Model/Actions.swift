public struct ModifierKeys: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let control = ModifierKeys(rawValue: 1 << 0)
    public static let option = ModifierKeys(rawValue: 1 << 1)
    public static let shift = ModifierKeys(rawValue: 1 << 2)
    public static let command = ModifierKeys(rawValue: 1 << 3)
}

public struct KeyShortcut: Codable, Hashable, Sendable {
    /// Virtual key code (kVK_*), e.g. 8 = C.
    public var keyCode: UInt16
    public var modifiers: ModifierKeys
    /// Key label captured while recording, e.g. "C" or "←".
    public var keyLabel: String

    public init(keyCode: UInt16, modifiers: ModifierKeys, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = keyLabel
    }

    /// Modifier symbols in macOS menu order followed by the key, e.g. "⌃⌥⇧⌘C".
    public var displayString: String {
        var result = ""
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }
        return result + keyLabel
    }
}

public enum SystemAction: String, Codable, CaseIterable, Sendable {
    case back, forward, missionControl, appExpose, desktopLeft, desktopRight, launchpad, showDesktop
}

public enum ButtonAction: Codable, Hashable, Sendable {
    case shortcut(KeyShortcut)
    case system(SystemAction)
}
