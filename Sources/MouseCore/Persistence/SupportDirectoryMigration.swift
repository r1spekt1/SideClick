import Foundation

/// Carries the settings over from a previous app name's support directory on first launch.
public enum SupportDirectoryMigration {
    public static let migratedFiles = ["settings.json", "pointer-originals.json"]

    /// Copies the known files from `old` into `new`. Does nothing when `new` already exists or
    /// `old` does not; the old directory is never modified. Returns whether anything was copied.
    @discardableResult
    public static func migrate(from old: URL, to new: URL, fileManager: FileManager = .default) throws -> Bool {
        guard !fileManager.fileExists(atPath: new.path), fileManager.fileExists(atPath: old.path) else {
            return false
        }
        do {
            try fileManager.createDirectory(at: new, withIntermediateDirectories: true)
            for name in migratedFiles {
                let source = old.appendingPathComponent(name)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.copyItem(at: source, to: new.appendingPathComponent(name))
            }
        } catch {
            // A half-copied directory would make the next launch skip the migration for good.
            try? fileManager.removeItem(at: new)
            throw error
        }
        return true
    }
}
