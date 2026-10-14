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
            if let battery = model.battery {
                Label(battery.title, systemImage: battery.symbolName)
                    .foregroundStyle(battery.isLow ? Color.red : Color.secondary)
            }
            if model.needsInputMonitoring {
                Button("Grant Input Monitoring to show the battery…") { model.requestInputMonitoring() }
            }
            if !model.isAccessibilityGranted {
                Button("Grant Accessibility access…") { model.requestAccessibility() }
            }
            if !model.conflicts.isEmpty {
                ConflictWarning(names: model.conflicts)
            }
            Divider()
            Toggle("Enabled", isOn: $model.settings.isEnabled)
            Toggle("Smooth scrolling", isOn: $model.settings.scroll.smoothEnabled)
            Toggle("Reverse scrolling", isOn: $model.settings.scroll.inverted)
            Divider()
            Button("Settings…") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .toggleStyle(.switch)
        .onAppear { model.refreshBattery() }
        .padding(14)
        .frame(width: 300, alignment: .leading)
    }
}
