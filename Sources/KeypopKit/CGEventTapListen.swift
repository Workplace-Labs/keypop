import ApplicationServices
import Foundation

/// CGEventTap keyboard listen path (Input Monitoring). Required for Warp, VS Code, Cursor.
public enum CGEventTapListen {
    static let keyboardEventMask: CGEventMask = {
        let keyDown = 1 << CGEventType.keyDown.rawValue
        let timeout = 1 << CGEventType.tapDisabledByTimeout.rawValue
        let userInput = 1 << CGEventType.tapDisabledByUserInput.rawValue
        return CGEventMask(keyDown | timeout | userInput)
    }()

    public static func probe() -> (created: Bool, enabled: Bool) {
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: keyboardEventMask,
            callback: passthroughCallback,
            userInfo: nil
        ) else {
            return (false, false)
        }
        let enabled = CGEvent.tapIsEnabled(tap: tap)
        CFMachPortInvalidate(tap)
        return (true, enabled)
    }

    /// Count keyDown events for `seconds` (diagnostic `probe listen`).
    public static func runProbe(seconds: TimeInterval, onKeyDown: @escaping (Int) -> Void) throws -> Int {
        final class State {
            var count = 0
            let onKeyDown: (Int) -> Void
            init(onKeyDown: @escaping (Int) -> Void) { self.onKeyDown = onKeyDown }
        }

        let state = State(onKeyDown: onKeyDown)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard type == .keyDown, let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let state = Unmanaged<State>.fromOpaque(userInfo).takeUnretainedValue()
            state.count += 1
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            state.onKeyDown(keyCode)
            return Unmanaged.passUnretained(event)
        }

        let installed = try install(
            userInfo: Unmanaged.passUnretained(state).toOpaque(),
            callback: callback
        )
        defer { teardown(tap: installed.tap, source: installed.source) }

        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
        return state.count
    }

    static func install(
        userInfo: UnsafeMutableRawPointer,
        callback: @escaping CGEventTapCallBack
    ) throws -> (tap: CFMachPort, source: CFRunLoopSource) {
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: keyboardEventMask,
            callback: callback,
            userInfo: userInfo
        ) else {
            throw ExpanderEngineError.tapCreateFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return (tap, source)
    }

    static func teardown(tap: CFMachPort?, source: CFRunLoopSource?) {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
    }

    private static let passthroughCallback: CGEventTapCallBack = { _, _, event, _ in
        Unmanaged.passUnretained(event)
    }
}
