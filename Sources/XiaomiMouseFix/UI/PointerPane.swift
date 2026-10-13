import SwiftUI

struct PointerPane: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section {
                Toggle("Customize pointer for external mice", isOn: $model.settings.pointer.isCustomized)
                Text("When off, the system mouse settings apply. Trackpads are never changed.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("Speed") {
                    Slider(value: $model.settings.pointer.speed, in: 0.25...4) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("Slow")
                    } maximumValueLabel: {
                        Text("Fast")
                    }
                }
                Toggle("Acceleration", isOn: $model.settings.pointer.accelerationEnabled)
                LabeledContent("Acceleration strength") {
                    Slider(value: $model.settings.pointer.acceleration, in: 0...3)
                }
                .disabled(!model.settings.pointer.accelerationEnabled)
            }
            .disabled(!model.settings.pointer.isCustomized)
        }
        .formStyle(.grouped)
    }
}
