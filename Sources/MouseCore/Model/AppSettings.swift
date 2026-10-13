import Foundation

public struct ButtonMapping: Codable, Hashable, Sendable {
    public var single: ButtonAction?
    public var double: ButtonAction?
    public var triple: ButtonAction?
    public var longPress: ButtonAction?

    public init(single: ButtonAction? = nil, double: ButtonAction? = nil,
                triple: ButtonAction? = nil, longPress: ButtonAction? = nil) {
        self.single = single
        self.double = double
        self.triple = triple
        self.longPress = longPress
    }

    public subscript(gesture: Gesture) -> ButtonAction? {
        get {
            switch gesture {
            case .single: single
            case .double: double
            case .triple: triple
            case .longPress: longPress
            }
        }
        set {
            switch gesture {
            case .single: single = newValue
            case .double: double = newValue
            case .triple: triple = newValue
            case .longPress: longPress = newValue
            }
        }
    }

    public var mappedGestures: Set<Gesture> {
        Set(Gesture.allCases.filter { self[$0] != nil })
    }
}

public struct PointerSettings: Codable, Hashable, Sendable {
    /// When false the app leaves the mouse at the system pointer settings.
    public var isCustomized = false
    public var accelerationEnabled = true
    /// macOS tracking speed, the mouse acceleration curve value (0...3).
    public var acceleration = 1.0

    public init() {}
}

public struct ScrollSettings: Codable, Hashable, Sendable {
    public var smoothEnabled = false
    /// Seconds a wheel notch takes to glide out (0.1...0.6).
    public var smoothDuration = 0.25
    /// Pixels one wheel notch scrolls in smooth mode (20...200).
    public var smoothPixelsPerLine = 60.0
    public var inverted = false
    /// Scales every wheel notch (0.25...5).
    public var lineMultiplier = 1.0
    public var shiftScrollsHorizontally = true

    public init() {}
}

public struct GestureTiming: Codable, Hashable, Sendable {
    /// Max seconds between a release and the next press to count as the same multi-click.
    public var multiClickWindow: TimeInterval
    /// Seconds a button must be held to fire a long press.
    public var longPressThreshold: TimeInterval

    public init(multiClickWindow: TimeInterval = 0.25, longPressThreshold: TimeInterval = 0.4) {
        self.multiClickWindow = multiClickWindow
        self.longPressThreshold = longPressThreshold
    }
}

public struct AppSettings: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion = AppSettings.currentSchemaVersion
    public var isEnabled = true
    public var pointer = PointerSettings()
    public var scroll = ScrollSettings()
    public var timing = GestureTiming()
    public var backButton = ButtonMapping(single: .system(.back))
    public var forwardButton = ButtonMapping(single: .system(.forward))

    public init() {}

    public subscript(button: SideButton) -> ButtonMapping {
        get { button == .back ? backButton : forwardButton }
        set {
            if button == .back { backButton = newValue } else { forwardButton = newValue }
        }
    }

    /// Tolerant decoding: any missing top-level section falls back to its default.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? defaults.schemaVersion
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? defaults.isEnabled
        pointer = try container.decodeIfPresent(PointerSettings.self, forKey: .pointer) ?? defaults.pointer
        scroll = try container.decodeIfPresent(ScrollSettings.self, forKey: .scroll) ?? defaults.scroll
        timing = try container.decodeIfPresent(GestureTiming.self, forKey: .timing) ?? defaults.timing
        backButton = try container.decodeIfPresent(ButtonMapping.self, forKey: .backButton) ?? defaults.backButton
        forwardButton = try container.decodeIfPresent(ButtonMapping.self, forKey: .forwardButton) ?? defaults.forwardButton
    }
}
