import MouseCore
import SwiftUI

/// One row on the Buttons pane: gesture → nothing / keyboard shortcut / system action.
struct GestureActionRow: View {
    let gesture: MouseCore.Gesture
    @Binding var action: ButtonAction?

    private enum Kind: Hashable {
        case none, shortcut, system
    }

    var body: some View {
        LabeledContent(gesture.title) {
            HStack {
                Picker("Action type", selection: kind) {
                    Text("None").tag(Kind.none)
                    Text("Shortcut").tag(Kind.shortcut)
                    Text("System action").tag(Kind.system)
                }
                .labelsHidden()
                .fixedSize()

                switch action {
                case .shortcut(let shortcut):
                    ShortcutRecorder(shortcut: Binding(get: { shortcut }, set: { action = .shortcut($0) }))
                case .system(let systemAction):
                    Picker("System action", selection: Binding(get: { systemAction }, set: { action = .system($0) })) {
                        ForEach(SystemAction.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                case nil:
                    EmptyView()
                }
            }
        }
    }

    private var kind: Binding<Kind> {
        Binding {
            switch action {
            case .shortcut: .shortcut
            case .system: .system
            case nil: .none
            }
        } set: { newKind in
            switch newKind {
            case .none:
                action = nil
            case .shortcut:
                if case .shortcut = action { return }
                action = .shortcut(KeyShortcut(keyCode: 8, modifiers: .command, keyLabel: "C"))
            case .system:
                if case .system = action { return }
                action = .system(.back)
            }
        }
    }
}
