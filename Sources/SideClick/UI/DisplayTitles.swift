import MouseCore

extension SideButton {
    var title: String {
        switch self {
        case .back: "Back button"
        case .forward: "Forward button"
        }
    }
}

extension Gesture {
    var title: String {
        switch self {
        case .single: "Single click"
        case .double: "Double click"
        case .triple: "Triple click"
        case .longPress: "Long press"
        }
    }
}

extension SystemAction {
    var title: String {
        switch self {
        case .back: "Back"
        case .forward: "Forward"
        case .missionControl: "Mission Control"
        case .appExpose: "App Exposé"
        case .desktopLeft: "Desktop left"
        case .desktopRight: "Desktop right"
        case .launchpad: "Apps (Launchpad)"
        case .showDesktop: "Show Desktop"
        }
    }
}
