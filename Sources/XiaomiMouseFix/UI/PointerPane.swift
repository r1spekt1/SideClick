import SwiftUI

struct PointerPane: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section {
                Toggle("Prilagodi pointer za Xiaomi miš", isOn: $model.settings.pointer.isCustomized)
                Text("Kad je isključeno, važe sistemska podešavanja miša. Trackpad se nikad ne menja.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("Brzina") {
                    Slider(value: $model.settings.pointer.speed, in: 0.25...4) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("Sporo")
                    } maximumValueLabel: {
                        Text("Brzo")
                    }
                }
                Toggle("Akceleracija", isOn: $model.settings.pointer.accelerationEnabled)
                LabeledContent("Jačina akceleracije") {
                    Slider(value: $model.settings.pointer.acceleration, in: 0...3)
                }
                .disabled(!model.settings.pointer.accelerationEnabled)
            }
            .disabled(!model.settings.pointer.isCustomized)
        }
        .formStyle(.grouped)
    }
}
