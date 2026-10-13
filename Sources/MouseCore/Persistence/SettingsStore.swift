import Foundation

/// Persists AppSettings as JSON. An unreadable file is moved aside to `<name>.bak`.
public final class SettingsStore {
    public let fileURL: URL

    public static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SideClick", isDirectory: true)
            .appendingPathComponent("settings.json")
    }

    public init(fileURL: URL = SettingsStore.defaultFileURL) {
        self.fileURL = fileURL
    }

    public func load() -> AppSettings {
        guard let data = try? Data(contentsOf: fileURL) else { return AppSettings() }
        do {
            var settings = try JSONDecoder().decode(AppSettings.self, from: data)
            settings.schemaVersion = AppSettings.currentSchemaVersion
            return settings
        } catch {
            backUpUnreadableFile()
            return AppSettings()
        }
    }

    public func save(_ settings: AppSettings) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: fileURL, options: .atomic)
    }

    private func backUpUnreadableFile() {
        let backup = fileURL.appendingPathExtension("bak")
        try? FileManager.default.removeItem(at: backup)
        try? FileManager.default.moveItem(at: fileURL, to: backup)
    }
}
