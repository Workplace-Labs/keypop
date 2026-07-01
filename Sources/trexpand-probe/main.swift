import ApplicationServices
import AppKit
import Foundation
import KSPrivateBridge
import TrexpandKit

enum ProbeCommand: String {
    case permissions
    case listen
    case inject
    case bridge
    case help
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

struct ProbeOptions {
    var command: ProbeCommand = .help
    var seconds: Double = 5
    var text: String = "trexpand-probe-inject-test"
    var json: Bool = true
}

func parseArgs(_ args: [String]) -> ProbeOptions {
    var options = ProbeOptions()
    guard args.count > 1 else { return options }

    guard let command = ProbeCommand(rawValue: args[1]) else {
        fputs("Unknown command: \(args[1])\n", stderr)
        return options
    }
    options.command = command

    var index = 2
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

func printJSON<T: Encodable>(_ value: T) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    if let line = String(data: data, encoding: .utf8) {
        print(line)
    }
}

func runPermissions(json: Bool) throws {
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

func runListen(seconds: Double) throws {
    let snapshot = PermissionProbe.snapshot()
    guard snapshot.readyForListen else {
        fputs("Listen not ready. Run: trexpand-probe permissions\n", stderr)
        exit(2)
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
        fputs("Failed to create event tap.\n", stderr)
        exit(2)
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    fputs("Listening for \(seconds)s — type in any app. Key events on stderr.\n", stderr)
    RunLoop.current.run(until: Date().addingTimeInterval(seconds))

    CGEvent.tapEnable(tap: tap, enable: false)
    try printJSON(ListenResult(keysSeen: state.count, seconds: seconds))
}

func runInject(text: String) throws {
    let injector = ClipboardInjector()
    try injector.inject(text)
    try printJSON(InjectResult(injected: text.count, method: "clipboard_cmd_v"))
}

func runBridge() throws {
    var error: NSError?
    let rows = KSTextReplacementList(&error)
    if let error {
        try printJSON(BridgeResult(ok: false, count: nil, source: nil, error: error.localizedDescription))
        exit(1)
    }
    try printJSON(BridgeResult(ok: true, count: rows.count, source: "KSTextReplacementList", error: nil))
}

func printHelp() {
    print(
        """
        trexpand-probe — Sprint 0 spike utilities for macOS text expansion

        Usage:
          trexpand-probe permissions [--plain]
          trexpand-probe listen --seconds 5
          trexpand-probe inject --text 'hello'
          trexpand-probe bridge

        Examples:
          trexpand-probe permissions
          trexpand-probe inject --text 'probe'    # focus a text field first
          trexpand-probe listen --seconds 5       # type keys; see stderr

        Requires Input Monitoring (listen) and Accessibility / post-event (inject).
        For LaunchAgent: grant TCC to ~/.local/Trexpand.app (not Terminal).
        For probe from Terminal: grant TCC to Terminal or run probe inside Trexpand.app.
        """
    )
}

let options = parseArgs(CommandLine.arguments)

do {
    switch options.command {
    case .permissions:
        try runPermissions(json: options.json)
    case .listen:
        try runListen(seconds: options.seconds)
    case .inject:
        try runInject(text: options.text)
    case .bridge:
        try runBridge()
    case .help:
        printHelp()
        exit(options.command == .help && CommandLine.arguments.count > 1 ? 1 : 0)
    }
} catch {
    fputs("Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
