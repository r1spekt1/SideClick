import MouseCore
import SwiftUI

@main
struct SideClickApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            MenuBarLabel(battery: model.battery)
        }
        .menuBarExtraStyle(.window)

        Window("SideClick", id: "settings") {
            SettingsView(model: model)
        }
        .windowResizability(.contentMinSize)
    }
}

/// The bundled template image (macOS tints it for the menu bar), or the SF Symbol when run unbundled,
/// followed by the mouse battery when it is known.
private struct MenuBarLabel: View {
    let battery: BatteryStatus?

    private static let icon: NSImage? = {
        let image = Bundle.main.image(forResource: "MenuBarIcon")
        image?.isTemplate = true
        return image
    }()

    var body: some View {
        Group {
            if let icon = Self.icon {
                Image(nsImage: icon)
            } else {
                Image(systemName: "computermouse")
            }
            if let battery {
                battery.isCharging ? Text(Image(systemName: "bolt.fill")) : Text(battery.title)
            }
        }
        .accessibilityLabel(battery.map { "SideClick, mouse battery \($0.title)" } ?? "SideClick")
    }
}
