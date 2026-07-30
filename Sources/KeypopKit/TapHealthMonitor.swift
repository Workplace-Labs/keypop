import Foundation

/// Infrequent, low-overhead checks for a silently dead CGEvent tap.
///
/// Mid-session idle silence is not treated as failure — use `keypop heal` or `;kpfix`
/// when the user notices expansion is broken. Automatic recovery focuses on
/// never-delivered taps (installed but never received a keyDown).
public struct TapHealthMonitorConfig: Sendable {
    public let checkIntervalSeconds: TimeInterval
    public let permissionProbeIntervalSeconds: TimeInterval
    /// No keyDown since install/reinstall for this long (after grace) ⇒ never-delivered inert.
    public let inertAfterSeconds: TimeInterval
    /// Suppress inert detection right after install/reinstall.
    public let startupGraceSeconds: TimeInterval
    /// After this many never-delivered reinstalls without recovery, exit for KeepAlive.
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
    /// Tap installed but has never delivered a keyDown (create-probe may still pass).
    case tapInert
}

public struct TapLivenessInput: Equatable, Sendable {
    public let secondsSinceInstall: TimeInterval
    public let inertAfterSeconds: TimeInterval
    public let gracePeriodActive: Bool
    public let everReceivedKeyDown: Bool

    public init(
        secondsSinceInstall: TimeInterval,
        inertAfterSeconds: TimeInterval,
        gracePeriodActive: Bool,
        everReceivedKeyDown: Bool
    ) {
        self.secondsSinceInstall = secondsSinceInstall
        self.inertAfterSeconds = inertAfterSeconds
        self.gracePeriodActive = gracePeriodActive
        self.everReceivedKeyDown = everReceivedKeyDown
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

        if let liveness, isNeverDelivered(liveness) {
            issues.append(.tapInert)
        }

        guard includePermissionProbe, let snapshot else {
            return issues
        }

        if !snapshot.tapCreateAllowed {
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

    /// Only the post-install blind-tap case. Idle silence after prior keyDowns is not inert.
    public static func isNeverDelivered(_ input: TapLivenessInput) -> Bool {
        guard !input.gracePeriodActive, !input.everReceivedKeyDown else { return false }
        return input.secondsSinceInstall >= input.inertAfterSeconds
    }

    public static func action(
        issues: [TapHealthIssue],
        consecutiveNeverDeliveredReinstalls: Int,
        maxInertReinstallsBeforeExit: Int = 1
    ) -> TapLivenessAction {
        guard issues.contains(.tapInert) else {
            return .none
        }
        if consecutiveNeverDeliveredReinstalls >= maxInertReinstallsBeforeExit {
            return .fatalExit
        }
        return .reinstall
    }
}
