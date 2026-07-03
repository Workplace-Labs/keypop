import Foundation
import KSPrivateBridge
import KeypopKit

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
        var request: Bool = false
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
            case "--request":
                options.request = true
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

    static func runPermissions(json: Bool, request: Bool) throws {
        if request {
            let listenRequested = PermissionProbe.requestListenAccess()
            let postRequested = PermissionProbe.requestPostAccess()
            fputs("request_listen=\(listenRequested) request_post=\(postRequested)\n", stderr)
        }

        let snapshot = PermissionProbe.snapshot()
        if json {
            try printJSON(snapshot)
        } else {
            print("ax_trusted=\(snapshot.axIsProcessTrusted)")
            print("listen_preflight=\(snapshot.listenEventPreflight)")
            print("post_preflight=\(snapshot.postEventPreflight)")
            print("live_tap_creates=\(snapshot.liveTapCreates)")
            print("live_tap_enabled=\(snapshot.liveTapEnabled)")
            print("stale_tcc_suspected=\(snapshot.staleTCCSuspected)")
            print("ready_for_listen=\(snapshot.readyForListen)")
            print("ready_for_inject=\(snapshot.readyForInject)")
            print("bundle=\(snapshot.bundleIdentifier)")
            print("executable=\(snapshot.executablePath)")
            print("plist_input_monitoring_key=\(snapshot.hasInputMonitoringUsageDescription)")
            print("plist_accessibility_key=\(snapshot.hasAccessibilityUsageDescription)")
        }
        PermissionProbe.logDiagnostics(snapshot, to: stderr)
    }

    static func runListen(seconds: Double) throws {
        let snapshot = PermissionProbe.snapshot()
        guard snapshot.readyForListen else {
            fputs("Listen not ready. Run: keypop probe permissions\n", stderr)
            throw CLIError.runtime("listen not ready")
        }

        fputs("Listening for \(seconds)s via CGEventTap — type in any app. Key events on stderr.\n", stderr)
        let count = try CGEventTapListen.runProbe(seconds: seconds) { keyCode in
            fputs("keydown|keycode=\(keyCode)\n", stderr)
        }
        try printJSON(ListenResult(keysSeen: count, seconds: seconds))
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
            try runPermissions(json: options.json, request: options.request)
        case .listen:
            try runListen(seconds: options.seconds)
        case .inject:
            try runInject(text: options.text)
        case .bridge:
            try runBridge()
        }
    }
}
