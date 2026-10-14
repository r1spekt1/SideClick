public enum MouseConnection: Equatable, Sendable {
    /// A 2.4 GHz USB receiver.
    case receiver
    case bluetooth
    /// The mouse's own USB cable.
    case wired
    /// USB, either a receiver or a cable; told apart only for known models.
    case usb
}

/// A connected mouse as the UI lists it.
public struct ConnectedMouse: Equatable, Sendable {
    public var name: String
    public var connection: MouseConnection?

    public init(name: String, connection: MouseConnection?) {
        self.name = name
        self.connection = connection
    }
}
