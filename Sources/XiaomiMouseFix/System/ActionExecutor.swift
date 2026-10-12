import AppKit
import CoreGraphics
import MouseCore

/// Performs a mapped action by posting synthetic input or launching system apps.
enum ActionExecutor {
    private static let missionControl = URL(fileURLWithPath: "/System/Applications/Mission Control.app/Contents/MacOS/Mission Control")
    private static let appsLauncher = URL(fileURLWithPath: "/System/Applications/Apps.app")

    static func perform(_ action: ButtonAction) {
        switch action {
        case .shortcut(let shortcut):
            postKey(CGKeyCode(shortcut.keyCode), flags: shortcut.modifiers.cgFlags)
        case .system(let action):
            perform(action)
        }
    }

    private static func perform(_ action: SystemAction) {
        switch action {
        case .back: postMouseClick(.back)
        case .forward: postMouseClick(.forward)
        case .missionControl: launchMissionControl(argument: nil)
        case .appExpose: launchMissionControl(argument: "2")
        case .showDesktop: launchMissionControl(argument: "1")
        case .launchpad: NSWorkspace.shared.openApplication(at: appsLauncher, configuration: .init())
        case .desktopLeft: postKey(123, flags: [.maskControl, .maskSecondaryFn])
        case .desktopRight: postKey(124, flags: [.maskControl, .maskSecondaryFn])
        }
    }

    private static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        for isDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown) else { continue }
            event.flags = flags
            SyntheticEvent.post(event)
        }
    }

    /// Re-posts the native side button so browsers handle Back/Forward themselves.
    private static func postMouseClick(_ button: SideButton) {
        let location = CGEvent(source: nil)?.location ?? .zero
        for type in [CGEventType.otherMouseDown, .otherMouseUp] {
            guard let event = CGEvent(mouseEventSource: nil, mouseType: type,
                                      mouseCursorPosition: location, mouseButton: .center) else { continue }
            event.setIntegerValueField(.mouseEventButtonNumber, value: button.cgButtonNumber)
            SyntheticEvent.post(event)
        }
    }

    private static func launchMissionControl(argument: String?) {
        let process = Process()
        process.executableURL = missionControl
        process.arguments = argument.map { [$0] } ?? []
        try? process.run()
    }
}
