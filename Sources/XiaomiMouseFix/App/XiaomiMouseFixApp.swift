import SwiftUI

@main
struct XiaomiMouseFixApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)

        Window("XiaomiMouseFix", id: "settings") {
            SettingsView(model: model)
        }
        .windowResizability(.contentMinSize)
    }
}

/// The bundled template image (macOS tints it for the menu bar), or the SF Symbol when run unbundled.
private struct MenuBarLabel: View {
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
        }
        .accessibilityLabel("XiaomiMouseFix")
    }
}
