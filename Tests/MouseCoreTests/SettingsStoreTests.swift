import Foundation
import Testing
@testable import MouseCore

@Suite struct SettingsStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    private var fileURL: URL { directory.appendingPathComponent("settings.json") }

    @Test func missingFileGivesDefaults() {
        #expect(SettingsStore(fileURL: fileURL).load() == AppSettings())
    }

    @Test func savedSettingsLoadBack() throws {
        let store = SettingsStore(fileURL: fileURL)
        var settings = AppSettings()
        settings.isEnabled = false
        settings[.back].double = .shortcut(KeyShortcut(keyCode: 9, modifiers: .command, keyLabel: "V"))
        settings.pointer.speed = 2
        try store.save(settings)
        #expect(store.load() == settings)
    }

    @Test func unreadableFileIsBackedUpAndDefaultsLoaded() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        #expect(SettingsStore(fileURL: fileURL).load() == AppSettings())
        let backup = fileURL.appendingPathExtension("bak")
        #expect(try String(contentsOf: backup, encoding: .utf8) == "not json")
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test func missingSectionsFallBackToDefaults() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{"isEnabled": false}"#.utf8).write(to: fileURL)
        let loaded = SettingsStore(fileURL: fileURL).load()
        #expect(loaded.isEnabled == false)
        #expect(loaded.scroll == ScrollSettings())
        #expect(loaded.backButton == AppSettings().backButton)
    }
}
