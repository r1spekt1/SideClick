import MouseCore

extension SideButton {
    var title: String {
        switch self {
        case .back: "Zadnje dugme"
        case .forward: "Prednje dugme"
        }
    }
}

extension Gesture {
    var title: String {
        switch self {
        case .single: "Jedan klik"
        case .double: "Dupli klik"
        case .triple: "Trostruki klik"
        case .longPress: "Dugo držanje"
        }
    }
}

extension SystemAction {
    var title: String {
        switch self {
        case .back: "Nazad"
        case .forward: "Napred"
        case .missionControl: "Mission Control"
        case .appExpose: "App Exposé"
        case .desktopLeft: "Desktop levo"
        case .desktopRight: "Desktop desno"
        case .launchpad: "Apps (Launchpad)"
        case .showDesktop: "Prikaži desktop"
        }
    }
}
