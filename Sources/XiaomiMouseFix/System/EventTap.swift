import CoreGraphics
import Foundation

/// One active CGEventTap on the main run loop. The handler must return the same event
/// (optionally modified) to pass it on, or nil to swallow it.
final class EventTap {
    typealias Handler = (CGEventType, CGEvent) -> CGEvent?

    private let location: CGEventTapLocation
    private let mask: CGEventMask
    private let handler: Handler
    private var port: CFMachPort?
    private var source: CFRunLoopSource?

    init(location: CGEventTapLocation = .cghidEventTap, events: [CGEventType], handler: @escaping Handler) {
        self.location = location
        self.mask = events.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        self.handler = handler
    }

    deinit { stop() }

    @discardableResult
    func start() -> Bool {
        if port != nil { return true }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let port = CGEvent.tapCreate(tap: location, place: .headInsertEventTap, options: .defaultTap,
                                           eventsOfInterest: mask, callback: eventTapCallback,
                                           userInfo: refcon) else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        self.port = port
        self.source = source
        return true
    }

    func stop() {
        guard let port else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        CFMachPortInvalidate(port)
        self.port = nil
        self.source = nil
    }

    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        return handler(type, event).map { Unmanaged.passUnretained($0) }
    }
}

private func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                              refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    return Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
}
