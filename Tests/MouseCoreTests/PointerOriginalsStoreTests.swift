import Foundation
import Testing
@testable import MouseCore

@Suite struct PointerOriginalsStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    private var fileURL: URL { directory.appendingPathComponent("pointer-originals.json") }
    private var store: PointerOriginalsStore { PointerOriginalsStore(fileURL: fileURL) }

    @Test func missingFileLoadsNil() {
        #expect(store.load() == nil)
    }

    @Test func perDeviceValuesRoundTrip() throws {
        var originals = PointerOriginals()
        originals["10007:20499"] = ["HIDPointerResolution": 26_214_400, "HIDMouseAcceleration": 65_536]
        originals["1133:49277"] = ["HIDPointerResolution": 52_428_800]
        try store.save(originals)
        #expect(store.load() == originals)
    }

    @Test func legacyFlatFileIsReadAsTheXiaomiEntry() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{"HIDMouseAcceleration":65536,"HIDPointerResolution":26214400}"#.utf8).write(to: fileURL)
        let loaded = try #require(store.load())
        #expect(loaded.devices.count == 1)
        #expect(loaded[PointerOriginals.legacyDeviceKey]
            == ["HIDMouseAcceleration": 65_536, "HIDPointerResolution": 26_214_400])
    }

    @Test func unreadableFileLoadsNil() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        #expect(store.load() == nil)
    }

    @Test func settingNilRemovesADevice() {
        var originals = PointerOriginals()
        originals["1:2"] = ["HIDPointerResolution": 1]
        originals["1:2"] = nil
        #expect(originals.isEmpty)
    }

    @Test func removeDeletesTheFileAndToleratesAMissingOne() throws {
        try store.save(PointerOriginals(devices: ["1:2": ["HIDPointerResolution": 1]]))
        try store.remove()
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        try store.remove()
    }
}
