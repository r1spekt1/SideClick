import Foundation
import Testing
@testable import MouseCore

@Suite struct SupportDirectoryMigrationTests {
    private let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    private var old: URL { root.appendingPathComponent("old", isDirectory: true) }
    private var new: URL { root.appendingPathComponent("new", isDirectory: true) }

    private func write(_ text: String, _ name: String, in directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: directory.appendingPathComponent(name))
    }

    private func read(_ name: String, in directory: URL) -> String? {
        try? String(contentsOf: directory.appendingPathComponent(name), encoding: .utf8)
    }

    @Test func copiesTheKnownFilesWhenTheNewDirectoryIsMissing() throws {
        try write("settings", "settings.json", in: old)
        try write("originals", "pointer-originals.json", in: old)
        #expect(try SupportDirectoryMigration.migrate(from: old, to: new))
        #expect(read("settings.json", in: new) == "settings")
        #expect(read("pointer-originals.json", in: new) == "originals")
    }

    @Test func leavesTheOldFilesInPlace() throws {
        try write("settings", "settings.json", in: old)
        try SupportDirectoryMigration.migrate(from: old, to: new)
        #expect(read("settings.json", in: old) == "settings")
    }

    @Test func copesWithOnlySomeFilesPresent() throws {
        try write("settings", "settings.json", in: old)
        #expect(try SupportDirectoryMigration.migrate(from: old, to: new))
        #expect(read("settings.json", in: new) == "settings")
        #expect(read("pointer-originals.json", in: new) == nil)
    }

    @Test func ignoresFilesItDoesNotKnow() throws {
        try write("settings", "settings.json", in: old)
        try write("junk", "settings.json.bak", in: old)
        try SupportDirectoryMigration.migrate(from: old, to: new)
        #expect(read("settings.json.bak", in: new) == nil)
    }

    @Test func doesNothingWhenTheNewDirectoryExists() throws {
        try write("old settings", "settings.json", in: old)
        try write("new settings", "settings.json", in: new)
        #expect(try !SupportDirectoryMigration.migrate(from: old, to: new))
        #expect(read("settings.json", in: new) == "new settings")
    }

    @Test func doesNothingWhenTheOldDirectoryIsMissing() throws {
        #expect(try !SupportDirectoryMigration.migrate(from: old, to: new))
        #expect(!FileManager.default.fileExists(atPath: new.path))
    }
}
