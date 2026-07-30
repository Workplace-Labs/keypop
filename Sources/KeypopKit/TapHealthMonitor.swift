import Foundation

/// Infrequent, low-overhead checks for a silently dead CGEvent tap.
public struct TapHealthMonitorConfig: Sendable {
    public let checkIntervalSeconds: TimeInterval
    public let permissionProbeIntervalSeconds: TimeInterval
    /// No keyDown on the production tap for this long (after grace) ⇒ inert.
    public let inertAfterSeconds: TimeInterval
    /// Suppress inert detection right after install/reinstall.
    public let startupGraceSeconds: TimeInterval
    /// After this many inert-driven reinstalls without recovery, exit for KeepAlive.
    public let maxInertReinstallsBeforeExit: Int

    public init(
        checkIntervalSeconds: TimeInterval = 120,
        permissionProbeIntervalSeconds: TimeInterval = 600,
        inertAfterSeconds: TimeInterval = 300,
        startupGraceSeconds: TimeInterval = 180,
        maxInertReinstallsBeforeExit: Int = 1
    ) {
        self.checkIntervalSeconds = checkIntervalSeconds
        self.permissionProbeIntervalSeconds = permissionProbeIntervalSeconds
        self.inertAfterSeconds = inertAfterSeconds
        self.startupGraceSeconds = startupGraceSeconds
        self.maxInertReinstallsBeforeExit = maxInertReinstallsBeforeExit
    }

    public static let `default` = TapHealthMonitorConfig()
}

public enum TapHealthIssue: Equatable, Sendable {
    case tapDisabled
    case listenPermissionLost
    case injectPermissionLost
    case staleTCCSuspected
    /// Tap object exists and may report enabled, but keyDown delivery has stopped.
    case tapInert
}

public struct TapLivenessInput: Equatable, Sendable {
    public let secondsSinceLastKeyDown: TimeInterval
    public let inertAfterSeconds: TimeInterval
    public let gracePeriodActive: Bool

    public init(
        secondsSinceLastKeyDown: TimeInterval,
        inertAfterSeconds: TimeInterval,
        gracePeriodActive: Bool
    ) {
        self.secondsSinceLastKeyDown = secondsSinceLastKeyDown
        self.inertAfterSeconds = inertAfterSeconds
        self.gracePeriodActive = gracePeriodActive
    }
}

public enum TapLivenessAction: Equatable, Sendable {
    case none
    case reinstall
    case fatalExit
}

public enum TapHealthMonitor {
    public static func evaluate(
        tapEnabled: Bool,
        snapshot: PermissionSnapshot? = nil,
        includePermissionProbe: Bool,
        liveness: TapLivenessInput? = nil
    ) -> [TapHealthIssue] {
        var issues: [TapHealthIssue] = []

        if !tapEnabled {
            issues.append(.tapDisabled)
        }

        if let liveness, isInert(liveness) {
            issues.append(.tapInert)
        }

        guard includePermissionProbe, let snapshot else {
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

    public static func isInert(_ input: TapLivenessInput) -> Bool {
        guard !input.gracePeriodActive else { return false }
        return input.secondsSinceLastKeyDown >= input.inertAfterSeconds
    }

    /// Decide recovery for liveness failures. Disabled/listen-lost reinstalls stay in the engine.
    public static func action(
        issues: [TapHealthIssue],
        consecutiveInertReinstalls: Int,
        maxInertReinstallsBeforeExit: Int = 1
    ) -> TapLivenessAction {
        guard issues.contains(.tapInert) else {
            return .none
        }
        if consecutiveInertReinstalls >= maxInertReinstallsBeforeExit {
            return .fatalExit
        }
        return .reinstall
    }
}
