import Foundation
import Testing
@testable import MouseCore

@Suite struct ModelTests {
    @Test func sideButtonMapsCGButtonNumbers() {
        #expect(SideButton(cgButtonNumber: 3) == .back)
        #expect(SideButton(cgButtonNumber: 4) == .forward)
        #expect(SideButton(cgButtonNumber: 2) == nil)
        #expect(SideButton.back.cgButtonNumber == 3)
        #expect(SideButton.forward.cgButtonNumber == 4)
    }

    @Test func gestureClickCounts() {
        #expect(Gesture.single.clickCount == 1)
        #expect(Gesture.triple.clickCount == 3)
        #expect(Gesture.longPress.clickCount == nil)
        #expect(Gesture(clickCount: 2) == .double)
        #expect(Gesture(clickCount: 4) == nil)
    }

    @Test func shortcutDisplayStringUsesMenuOrder() {
        let shortcut = KeyShortcut(keyCode: 8, modifiers: [.command, .shift, .control, .option], keyLabel: "C")
        #expect(shortcut.displayString == "⌃⌥⇧⌘C")
    }

    @Test func buttonMappingSubscriptAndMappedGestures() {
        var mapping = ButtonMapping()
        #expect(mapping.mappedGestures.isEmpty)
        mapping[.double] = .system(.missionControl)
        mapping[.longPress] = .system(.appExpose)
        #expect(mapping.double == .system(.missionControl))
        #expect(mapping.mappedGestures == [.double, .longPress])
    }

    @Test func defaultSettingsKeepNativeBackAndForward() {
        let settings = AppSettings()
        #expect(settings[.back].single == .system(.back))
        #expect(settings[.forward].single == .system(.forward))
        #expect(settings.pointer.isCustomized == false)
    }

    @Test func settingsRoundTripThroughJSON() throws {
        var settings = AppSettings()
        settings[.back].double = .shortcut(KeyShortcut(keyCode: 9, modifiers: .command, keyLabel: "V"))
        settings.scroll.inverted = true
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(AppSettings.self, from: data) == settings)
    }
}
