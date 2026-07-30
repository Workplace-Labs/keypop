import Foundation

/// Infrequent, low-overhead checks for a silently dead CGEvent tap.
public struct TapHealthMonitorConfig: Sendable {
    public let checkIntervalSeconds: TimeInterval
    public let permissionProbeIntervalSeconds: TimeInterval
    /// No keyDown since install/reinstall for this long (after grace) ⇒ never-delivered inert.
    public let inertAfterSeconds: TimeInterval
    /// Had keyDowns, then silence this long ⇒ soft reinstall only (never fatal; idle users look like this).
    public let stalledAfterSeconds: TimeInterval
    /// Suppress inert detection right after install/reinstall.
    public let startupGraceSeconds: TimeInterval
    /// After this many never-delivered reinstalls without recovery, exit for KeepAlive.
    public let maxInertReinstallsBeforeExit: Int

    public init(
        checkIntervalSeconds: TimeInterval = 120,
        permissionProbeIntervalSeconds: TimeInterval = 600,
        inertAfterSeconds: TimeInterval = 300,
        stalledAfterSeconds: TimeInterval = 1800,
        startupGraceSeconds: TimeInterval = 180,
        maxInertReinstallsBeforeExit: Int = 1
    ) {
        self.checkIntervalSeconds = checkIntervalSeconds
        self.permissionProbeIntervalSeconds = permissionProbeIntervalSeconds
        self.inertAfterSeconds = inertAfterSeconds
        self.stalledAfterSeconds = stalledAfterSeconds
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
    /// Tap object exists / create-probe may pass, but keyDown delivery looks wrong.
    case tapInert
}

/// Why liveness failed. Wall-clock silence alone is not enough for a hard failure.
public enum TapInertKind: Equatable, Sendable {
    /// Zero keyDown callbacks since the current tap was installed.
    case neverDelivered
    /// Saw keyDowns earlier, then a long silence (may be idle user or a late death).
    case stalled
}

public struct TapLivenessInput: Equatable, Sendable {
    public let secondsSinceAnchor: TimeInterval
    public let inertAfterSeconds: TimeInterval
    public let stalledAfterSeconds: TimeInterval
    public let gracePeriodActive: Bool
    public let everReceivedKeyDown: Bool

    public init(
        secondsSinceAnchor: TimeInterval,
        inertAfterSeconds: TimeInterval,
        stalledAfterSeconds: TimeInterval,
        gracePeriodActive: Bool,
        everReceivedKeyDown: Bool
    ) {
        self.secondsSinceAnchor = secondsSinceAnchor
        self.inertAfterSeconds = inertAfterSeconds
        self.stalledAfterSeconds = stalledAfterSeconds
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

        if let liveness, inertKind(liveness) != nil {
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

    public static func inertKind(_ input: TapLivenessInput) -> TapInertKind? {
        guard !input.gracePeriodActive else { return nil }
        if !input.everReceivedKeyDown {
            return input.secondsSinceAnchor >= input.inertAfterSeconds ? .neverDelivered : nil
        }
        return input.secondsSinceAnchor >= input.stalledAfterSeconds ? .stalled : nil
    }

    /// Decide recovery for liveness failures.
    ///
    /// - `neverDelivered`: reinstall, then fatal — the tap is lying about health.
    /// - `stalled`: soft reinstall only — idle users look identical to a late tap death.
    public static func action(
        issues: [TapHealthIssue],
        inertKind: TapInertKind?,
        consecutiveNeverDeliveredReinstalls: Int,
        maxInertReinstallsBeforeExit: Int = 1
    ) -> TapLivenessAction {
        guard issues.contains(.tapInert), let inertKind else {
            return .none
        }
        switch inertKind {
        case .stalled:
            return .reinstall
        case .neverDelivered:
            if consecutiveNeverDeliveredReinstalls >= maxInertReinstallsBeforeExit {
                return .fatalExit
            }
            return .reinstall
        }
    }
}
