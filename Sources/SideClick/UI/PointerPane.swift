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
                Toggle("Acceleration", isOn: $model.settings.pointer.accelerationEnabled)
                LabeledContent("Tracking speed") {
                    Slider(value: $model.settings.pointer.acceleration, in: 0...3) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("Slow")
                    } maximumValueLabel: {
                        Text("Fast")
                    }
                }
                .disabled(!model.settings.pointer.accelerationEnabled)
            }
            .disabled(!model.settings.pointer.isCustomized)
        }
        .formStyle(.grouped)
    }
}
