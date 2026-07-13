import ApplicationServices
import Foundation

public struct PermissionSnapshot: Codable, Equatable, Sendable {
    public let axIsProcessTrusted: Bool
    public let listenEventPreflight: Bool
    public let postEventPreflight: Bool
    public let liveTapCreates: Bool
    public let liveTapEnabled: Bool
    public let staleTCCSuspected: Bool
    public let readyForListen: Bool
    public let readyForInject: Bool
    public let bundleIdentifier: String
    public let executablePath: String
    public let hasInputMonitoringUsageDescription: Bool
    public let hasAccessibilityUsageDescription: Bool
}

public enum PermissionProbe {
    private static func appBundlePath() -> String {
        Bundle.main.bundlePath
    }

    public static func snapshot() -> PermissionSnapshot {
        let axTrusted = AXIsProcessTrusted()
        let listenPreflight = CGPreflightListenEventAccess()
        let postPreflight = CGPreflightPostEventAccess()
        let tapState = CGEventTapListen.probe()
        let bundle = Bundle.main
        let info = bundle.infoDictionary ?? [:]

        let tapReady = tapState.created && tapState.enabled

        return PermissionSnapshot(
            axIsProcessTrusted: axTrusted,
            listenEventPreflight: listenPreflight,
            postEventPreflight: postPreflight,
            liveTapCreates: tapState.created,
            liveTapEnabled: tapState.enabled,
            staleTCCSuspected: listenPreflight && !tapReady,
            readyForListen: tapReady,
            readyForInject: postPreflight,
            bundleIdentifier: bundle.bundleIdentifier ?? "(none)",
            executablePath: bundle.executableURL?.path ?? ProcessInfo.processInfo.arguments.first ?? "(unknown)",
            hasInputMonitoringUsageDescription: info["NSInputMonitoringUsageDescription"] != nil,
            hasAccessibilityUsageDescription: info["NSAccessibilityUsageDescription"] != nil
        )
    }

    public static func requestListenAccess() -> Bool {
        CGRequestListenEventAccess()
    }

    public static func requestPostAccess() -> Bool {
        CGRequestPostEventAccess()
    }

    public static func logDiagnostics(_ snapshot: PermissionSnapshot, to stream: UnsafeMutablePointer<FILE>) {
        fputs("permission_debug|bundle=\(snapshot.bundleIdentifier)\n", stream)
        fputs("permission_debug|executable=\(snapshot.executablePath)\n", stream)
        fputs(
            "permission_debug|tap_creates=\(snapshot.liveTapCreates) tap_enabled=\(snapshot.liveTapEnabled) listen_preflight=\(snapshot.listenEventPreflight)\n",
            stream
        )
        fputs(
            "permission_debug|post_preflight=\(snapshot.postEventPreflight) ax_trusted=\(snapshot.axIsProcessTrusted)\n",
            stream
        )

        if !snapshot.readyForListen {
            fputs(
                "permission_hint|Grant Input Monitoring to \(appBundlePath()) (remove old entry, re-add via Cmd+Shift+G)\n",
                stream
            )
        }
        if snapshot.staleTCCSuspected {
            fputs(
                "permission_hint|TCC preflight true but tap failed — stale grant from old signature; run ./scripts/fix-keypop-tcc.sh\n",
                stream
            )
        }
        if !snapshot.hasInputMonitoringUsageDescription {
            fputs(
                "permission_hint|Rebuild KeyPop.app with ./scripts/install-full.sh (missing NSInputMonitoringUsageDescription)\n",
                stream
            )
        }
        if !snapshot.hasAccessibilityUsageDescription {
            fputs(
                "permission_hint|Rebuild KeyPop.app with ./scripts/install-full.sh (missing NSAccessibilityUsageDescription)\n",
                stream
            )
        }
        if !snapshot.postEventPreflight {
            fputs(
                "permission_hint|Grant Accessibility to \(appBundlePath()) for text injection\n",
                stream
            )
        }
    }
}
