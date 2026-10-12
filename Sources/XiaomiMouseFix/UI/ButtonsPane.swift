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
                        Picker("Dugme", selection: $selected) {
                            ForEach(SideButton.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text("Pritisni side dugme na mišu: osvetliće se na slici.")
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
            Section("Vreme") {
                LabeledContent("Prozor za više klikova") {
                    HStack {
                        Slider(value: $model.settings.timing.multiClickWindow, in: 0.15...0.6)
                        milliseconds(model.settings.timing.multiClickWindow)
                    }
                }
                LabeledContent("Prag za dugo držanje") {
                    HStack {
                        Slider(value: $model.settings.timing.longPressThreshold, in: 0.25...1.0)
                        milliseconds(model.settings.timing.longPressThreshold)
                    }
                }
                Text("Ako dugme ima samo „Jedan klik”, akcija se okida odmah, bez čekanja.")
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
