import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, pointer, scroll, buttons, about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .pointer: "Pointer"
        case .scroll: "Scroll"
        case .buttons: "Buttons"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .pointer: "cursorarrow.motionlines"
        case .scroll: "scroll"
        case .buttons: "computermouse"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var selection: SettingsPane? = .buttons

    private let panes = SettingsPane.allCases

    var body: some View {
        NavigationSplitView {
            List(panes, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.icon).tag(pane)
            }
            .navigationSplitViewColumnWidth(180)
        } detail: {
            detail(for: selection ?? .general)
                .frame(minWidth: 480, minHeight: 440)
                .navigationTitle((selection ?? .general).title)
        }
    }

    @ViewBuilder
    private func detail(for pane: SettingsPane) -> some View {
        switch pane {
        case .general: GeneralPane(model: model)
        case .pointer: PointerPane(model: model)
        case .scroll: ScrollPane(model: model)
        case .buttons: ButtonsPane(model: model)
        case .about: AboutPane()
        }
    }
}
