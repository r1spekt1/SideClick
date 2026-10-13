import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "computermouse.fill")
                Text(model.mouseTitle).font(.headline).lineLimit(1).truncationMode(.tail)
                Spacer()
                Circle()
                    .fill(model.isMouseConnected ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(model.isMouseConnected ? "Connected" : "Not connected")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !model.isAccessibilityGranted {
                Button("Odobri Accessibility pristup…") { model.requestAccessibility() }
            }
            if !model.conflicts.isEmpty {
                ConflictWarning(names: model.conflicts)
            }
            Divider()
            Toggle("Uključeno", isOn: $model.settings.isEnabled)
            Toggle("Glatko skrolovanje", isOn: $model.settings.scroll.smoothEnabled)
            Toggle("Obrni skrolovanje", isOn: $model.settings.scroll.inverted)
            Divider()
            Button("Podešavanja…") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Izađi") { NSApp.terminate(nil) }
        }
        .toggleStyle(.switch)
        .padding(14)
        .frame(width: 300, alignment: .leading)
    }
}
