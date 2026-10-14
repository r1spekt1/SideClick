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

extension BatteryStatus {
    /// While charging the mouse reports 100 %, so the level is not shown then.
    var title: String { isCharging ? "Charging" : "\(percent)%" }

    var symbolName: String {
        if isCharging { return "battery.100percent.bolt" }
        switch percent {
        case 88...: return "battery.100percent"
        case 63...: return "battery.75percent"
        case 38...: return "battery.50percent"
        case 13...: return "battery.25percent"
        default: return "battery.0percent"
        }
    }
}
