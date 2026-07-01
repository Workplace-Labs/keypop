import ApplicationServices
import AppKit
import Foundation
import KSPrivateBridge
import KeypopKit

private final class KeyListenState {
    var count = 0
}

private func keyListenCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }
    let state = Unmanaged<KeyListenState>.fromOpaque(userInfo).takeUnretainedValue()
    if type == .keyDown {
        state.count += 1
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        fputs("keydown|\(state.count)|keycode=\(keyCode)\n", stderr)
    }
    return Unmanaged.passUnretained(event)
}

enum ProbeCommands {
    enum Subcommand: String {
        case permissions
        case listen
        case inject
        case bridge
    }

    struct Options {
        var seconds: Double = 5
        var text: String = "keypop-probe-inject-test"
        var json: Bool = true
    }

    struct ListenResult: Codable {
        let keysSeen: Int
        let seconds: Double
    }

    struct InjectResult: Codable {
        let injected: Int
        let method: String
    }

    struct BridgeResult: Codable {
        let ok: Bool
        let count: Int?
        let source: String?
        let error: String?
    }

    static func parseArgs(_ args: [String]) -> Options {
        var options = Options()
        var index = 0
        while index < args.count {
            switch args[index] {
            case "--seconds":
                index += 1
                if index < args.count, let value = Double(args[index]) {
                    options.seconds = value
                }
            case "--text":
                index += 1
                if index < args.count {
                    options.text = args[index]
                }
            case "--plain":
                options.json = false
            default:
                fputs("Unknown flag: \(args[index])\n", stderr)
            }
            index += 1
        }
        return options
    }

    static func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        if let line = String(data: data, encoding: .utf8) {
            print(line)
        }
    }

    static func runPermissions(json: Bool) throws {
        let snapshot = PermissionProbe.snapshot()
        if json {
            try printJSON(snapshot)
        } else {
            print("ax_trusted=\(snapshot.axIsProcessTrusted)")
            print("listen_preflight=\(snapshot.listenEventPreflight)")
            print("post_preflight=\(snapshot.postEventPreflight)")
            print("live_tap_creates=\(snapshot.liveTapCreates)")
            print("live_tap_enabled=\(snapshot.liveTapEnabled)")
            print("stale_ax_cache_suspected=\(snapshot.staleAxCacheSuspected)")
            print("ready_for_listen=\(snapshot.readyForListen)")
            print("ready_for_inject=\(snapshot.readyForInject)")
        }
    }

    static func runListen(seconds: Double) throws {
        let snapshot = PermissionProbe.snapshot()
        guard snapshot.readyForListen else {
            fputs("Listen not ready. Run: keypop probe permissions\n", stderr)
            throw CLIError.runtime("listen not ready")
        }

        let state = KeyListenState()
        let userInfo = Unmanaged.passUnretained(state).toOpaque()
        let mask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: keyListenCallback,
            userInfo: userInfo
        ) else {
            throw CLIError.runtime("Failed to create event tap")
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        fputs("Listening for \(seconds)s — type in any app. Key events on stderr.\n", stderr)
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))

        CGEvent.tapEnable(tap: tap, enable: false)
        try printJSON(ListenResult(keysSeen: state.count, seconds: seconds))
    }

    static func runInject(text: String) throws {
        let injector = ClipboardInjector()
        try injector.inject(text)
        try printJSON(InjectResult(injected: text.count, method: "clipboard_cmd_v"))
    }

    static func runBridge() throws {
        var error: NSError?
        let rows = KSTextReplacementList(&error)
        if let error {
            try printJSON(BridgeResult(ok: false, count: nil, source: nil, error: error.localizedDescription))
            throw CLIError.runtime(error.localizedDescription)
        }
        try printJSON(BridgeResult(ok: true, count: rows.count, source: "KSTextReplacementList", error: nil))
    }

    static func run(subcommand: String, args: [String]) throws {
        guard let command = Subcommand(rawValue: subcommand) else {
            throw CLIError.usage(KeypopCLI.probeUsage())
        }
        let options = parseArgs(args)

        switch command {
        case .permissions:
            try runPermissions(json: options.json)
        case .listen:
            try runListen(seconds: options.seconds)
        case .inject:
            try runInject(text: options.text)
        case .bridge:
            try runBridge()
        }
    }
}
