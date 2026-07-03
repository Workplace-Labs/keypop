import Foundation

/// Infrequent, low-overhead checks for a silently dead CGEvent tap.
public struct TapHealthMonitorConfig: Sendable {
    public let checkIntervalSeconds: TimeInterval
    public let permissionProbeIntervalSeconds: TimeInterval

    public init(
        checkIntervalSeconds: TimeInterval = 120,
        permissionProbeIntervalSeconds: TimeInterval = 600
    ) {
        self.checkIntervalSeconds = checkIntervalSeconds
        self.permissionProbeIntervalSeconds = permissionProbeIntervalSeconds
    }

    public static let `default` = TapHealthMonitorConfig()
}

public enum TapHealthIssue: Equatable, Sendable {
    case tapDisabled
    case listenPermissionLost
    case injectPermissionLost
    case staleTCCSuspected
}

public enum TapHealthMonitor {
    public static func evaluate(
        tapEnabled: Bool,
        snapshot: PermissionSnapshot,
        includePermissionProbe: Bool
    ) -> [TapHealthIssue] {
        var issues: [TapHealthIssue] = []

        if !tapEnabled {
            issues.append(.tapDisabled)
        }

        guard includePermissionProbe else {
            return issues
        }

        if !snapshot.readyForListen {
            issues.append(.listenPermissionLost)
        }
        if !snapshot.readyForInject {
            issues.append(.injectPermissionLost)
        }
        if snapshot.staleTCCSuspected {
            issues.append(.staleTCCSuspected)
        }

        return issues
    }
}
