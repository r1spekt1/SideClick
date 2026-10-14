public enum MouseConnection: Equatable, Sendable {
    /// A 2.4 GHz USB receiver.
    case receiver
    /// Classic Bluetooth. It has no GATT Battery Service, so its battery can't be read.
    case bluetooth
    /// Bluetooth Low Energy, whose battery can be read through the standard Battery Service.
    case bluetoothLE
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

    /// Sorted by name. Equal names are sorted by connection, the link in use first: a receiver
    /// still lists its mouse while that mouse is on Bluetooth or its cable. Every connection has
    /// its own rank, so the order never depends on the input order.
    public static func sorted(_ mice: some Sequence<ConnectedMouse>) -> [ConnectedMouse] {
        mice.sorted { ($0.name, $0.rank) < ($1.name, $1.rank) }
    }

    private var rank: Int {
        switch connection {
        case .wired: 0
        case .bluetoothLE: 1
        case .bluetooth: 2
        case .receiver: 3
        case .usb: 4
        case nil: 5
        }
    }
}
