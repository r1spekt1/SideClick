import AppKit
import CoreGraphics

/// Finds other processes with an active (filtering) event tap on extra mouse buttons,
/// which would swallow the side buttons before we see them.
enum ConflictDetector {
    static func conflictingProcessNames() -> [String] {
        var count: UInt32 = 0
        guard CGGetEventTapList(0, nil, &count) == .success, count > 0 else { return [] }
        var taps = [CGEventTapInformation](repeating: CGEventTapInformation(), count: Int(count))
        guard CGGetEventTapList(count, &taps, &count) == .success else { return [] }

        let otherMouse = (CGEventMask(1) << CGEventType.otherMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.otherMouseUp.rawValue)
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let pids = Set(taps.prefix(Int(count))
            .filter { $0.enabled && $0.options == .defaultTap && $0.eventsOfInterest & otherMouse != 0 }
            .map(\.tappingProcess)
            .filter { $0 != ownPID })
        return pids.map { NSRunningApplication(processIdentifier: $0)?.localizedName ?? "PID \($0)" }.sorted()
    }
}
