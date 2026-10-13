import Foundation

/// Pointer HID values the system had before we changed them, per device model
/// (`HIDDeviceInfo.key`, e.g. "10007:20499").
public struct PointerOriginals: Equatable, Sendable {
    public typealias Values = [String: Int]

    /// Key under which a pre-0.2 flat file is read: that version only ever touched the Xiaomi mouse
    /// (vendor 0x2717 = 10007, product 0x5013 = 20499).
    public static let legacyDeviceKey = "10007:20499"

    public private(set) var devices: [String: Values]

    public init(devices: [String: Values] = [:]) {
        self.devices = devices
    }

    public var isEmpty: Bool { devices.isEmpty }

    public subscript(deviceKey: String) -> Values? {
        get { devices[deviceKey] }
        set { devices[deviceKey] = newValue }
    }
}

/// Keeps the originals on disk, so a crashed or killed run does not leave the next launch
/// capturing our custom values as if they were the system's.
public final class PointerOriginalsStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// nil when the file is missing or unreadable.
    public func load() -> PointerOriginals? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        if let devices = try? decoder.decode([String: PointerOriginals.Values].self, from: data) {
            return PointerOriginals(devices: devices)
        }
        if let flat = try? decoder.decode(PointerOriginals.Values.self, from: data) {
            return PointerOriginals(devices: [PointerOriginals.legacyDeviceKey: flat])
        }
        return nil
    }

    public func save(_ originals: PointerOriginals) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(originals.devices).write(to: fileURL, options: .atomic)
    }

    public func remove() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
