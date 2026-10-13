import MouseCore
import SwiftUI

struct ButtonsPane: View {
    @ObservedObject var model: AppModel
    @State private var selected: SideButton = .back

    var body: some View {
        Form {
            Section {
                HStack(spacing: 24) {
                    MouseIllustration(selected: $selected, pressed: model.pressedButtons)
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Button", selection: $selected) {
                            ForEach(SideButton.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text("Press a side button on your mouse: it lights up in the picture.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Section(selected.title) {
                ForEach(MouseCore.Gesture.allCases, id: \.self) { gesture in
                    GestureActionRow(gesture: gesture, action: binding(for: gesture))
                }
            }
            // New rows per button, so an armed shortcut recorder cannot record into another button.
            .id(selected)
            Section("Timing") {
                LabeledContent("Multi-click window") {
                    HStack {
                        Slider(value: $model.settings.timing.multiClickWindow, in: 0.15...0.6)
                        milliseconds(model.settings.timing.multiClickWindow)
                    }
                }
                LabeledContent("Long-press threshold") {
                    HStack {
                        Slider(value: $model.settings.timing.longPressThreshold, in: 0.25...1.0)
                        milliseconds(model.settings.timing.longPressThreshold)
                    }
                }
                Text("If a button only has \"Single click\", the action fires immediately, without waiting.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for gesture: MouseCore.Gesture) -> Binding<ButtonAction?> {
        Binding(get: { model.settings[selected][gesture] },
                set: { model.settings[selected][gesture] = $0 })
    }

    private func milliseconds(_ seconds: Double) -> some View {
        Text("\(Int(seconds * 1000)) ms").monospacedDigit().frame(width: 56, alignment: .trailing)
    }
}
