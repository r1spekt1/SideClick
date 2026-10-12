import SwiftUI

@main
struct XiaomiMouseFixApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("XiaomiMouseFix", systemImage: "computermouse") {
            MenuBarView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
