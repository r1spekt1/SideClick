import AppKit
import MouseCore
import SwiftUI

/// Button that records the next key combination pressed while it is active. Escape cancels.
struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(isRecording ? "Press a shortcut…" : shortcut.displayString) {
            isRecording ? stopRecording() : startRecording()
        }
        .monospaced()
        .onDisappear(perform: stopRecording)
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode != 53 {
                shortcut = KeyShortcut(keyCode: event.keyCode,
                                       modifiers: ModifierKeys(event.modifierFlags),
                                       keyLabel: KeyLabel.label(for: event))
            }
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }
}

private enum KeyLabel {
    private static let special: [UInt16: String] = [
        123: "←", 124: "→", 125: "↓", 126: "↑", 36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 117: "⌦",
        115: "Home", 119: "End", 116: "PgUp", 121: "PgDn",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    static func label(for event: NSEvent) -> String {
        special[event.keyCode] ?? (event.charactersIgnoringModifiers ?? "?").uppercased()
    }
}
