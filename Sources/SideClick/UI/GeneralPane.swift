import MouseCore
import SwiftUI

struct GeneralPane: View {
    @ObservedObject var model: AppModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Enable SideClick", isOn: $model.settings.isEnabled)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        // Reverting the toggle after a failure re-enters here; ignore that.
                        guard enabled != LaunchAtLogin.isEnabled else { return }
                        do {
                            try LaunchAtLogin.set(enabled)
                            launchError = nil
                        } catch {
                            launchError = error.localizedDescription
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                    }
                if let launchError {
                    Text(launchError).font(.caption).foregroundStyle(.red)
                }
            }
            Section("Status") {
                LabeledContent("Mouse", value: model.isMouseConnected
                    ? model.connectedMice.map { $0.isEmpty ? "Mouse" : $0 }.joined(separator: ", ") : "Not connected")
                LabeledContent("Accessibility") {
                    if model.isAccessibilityGranted {
                        Text("Granted")
                    } else {
                        Button("Grant…") { model.requestAccessibility() }
                    }
                }
            }
            if !model.conflicts.isEmpty {
                Section { ConflictWarning(names: model.conflicts) }
            }
            Section {
                Button("Restore default settings", role: .destructive) { model.settings = AppSettings() }
            }
        }
        .formStyle(.grouped)
    }
}
