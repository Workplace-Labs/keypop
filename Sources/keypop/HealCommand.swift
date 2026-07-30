import Darwin
import Foundation
import KeypopKit

enum HealCommand {
    static func run(args: [String]) -> Int32 {
        let reason = parseReason(args) ?? "cli"
        do {
            try ControlPlane.requestHeal(reason: reason)
        } catch {
            fputs("error: could not write heal request: \(error)\n", stderr)
            return 1
        }

        if daemonAppearsRunning() {
            if waitForHealConsumption(timeoutSeconds: 2.0) {
                print("heal|ready|daemon_reinstalled_tap")
                print("Try a shortcut (or type \(BuiltInSnippets.fixKeyword)) to confirm.")
                return 0
            }
            fputs("heal|daemon_did_not_consume_request — restarting LaunchAgent\n", stderr)
        } else {
            fputs("heal|daemon_not_running — starting LaunchAgent\n", stderr)
        }

        let status = restartLaunchAgent()
        if status == 0 {
            print("heal|ready|launchagent_restarted")
            print("Try a shortcut (or type \(BuiltInSnippets.fixKeyword)) to confirm.")
            return 0
        }
        fputs("error: LaunchAgent restart failed (exit \(status)). Run: ./scripts/launch-keypop.sh restart\n", stderr)
        return 1
    }

    private static func parseReason(_ args: [String]) -> String? {
        var index = 0
        while index < args.count {
            if args[index] == "--reason", index + 1 < args.count {
                return args[index + 1]
            }
            index += 1
        }
        return nil
    }

    private static func daemonAppearsRunning() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "keypop run --snippets"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func waitForHealConsumption(timeoutSeconds: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if !ControlPlane.healRequestPending() {
                return true
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return !ControlPlane.healRequestPending()
    }

    private static func restartLaunchAgent() -> Int32 {
        let uid = getuid()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["kickstart", "-k", "gui/\(uid)/io.keypop.daemon"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return 1
        }
    }
}
