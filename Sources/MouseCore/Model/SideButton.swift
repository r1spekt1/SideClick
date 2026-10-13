/// The two side buttons of a mouse, identified by their CGEvent button number.
public enum SideButton: String, Codable, CaseIterable, Sendable {
    /// Rear side button (HID button 4).
    case back
    /// Front side button (HID button 5).
    case forward

    public init?(cgButtonNumber: Int64) {
        switch cgButtonNumber {
        case 3: self = .back
        case 4: self = .forward
        default: return nil
        }
    }

    public var cgButtonNumber: Int64 {
        switch self {
        case .back: 3
        case .forward: 4
        }
    }
}

public enum Gesture: String, Codable, CaseIterable, Sendable {
    case single, double, triple, longPress

    /// Number of clicks for click gestures, nil for long press.
    public var clickCount: Int? {
        switch self {
        case .single: 1
        case .double: 2
        case .triple: 3
        case .longPress: nil
        }
    }

    public init?(clickCount: Int) {
        switch clickCount {
        case 1: self = .single
        case 2: self = .double
        case 3: self = .triple
        default: return nil
        }
    }
}
