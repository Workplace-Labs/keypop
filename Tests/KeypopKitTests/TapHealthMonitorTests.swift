import XCTest
@testable import KeypopKit

final class TapHealthMonitorTests: XCTestCase {
    func testTapDisabledOnlyOnLightCheck() {
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: false,
            includePermissionProbe: false
        )
        XCTAssertEqual(issues, [.tapDisabled])
    }

    func testPermissionProbeFindsStaleTCC() {
        let snapshot = PermissionSnapshot(
            axIsProcessTrusted: true,
            listenEventPreflight: true,
            postEventPreflight: true,
            liveTapCreates: false,
            liveTapEnabled: false,
            staleTCCSuspected: true,
            tapCreateAllowed: false,
            readyForInject: true,
            bundleIdentifier: "io.keypop.app",
            executablePath: "/test/keypop",
            hasInputMonitoringUsageDescription: true,
            hasAccessibilityUsageDescription: true
        )
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: snapshot,
            includePermissionProbe: true
        )
        XCTAssertTrue(issues.contains(.listenPermissionLost))
        XCTAssertTrue(issues.contains(.staleTCCSuspected))
    }

    func testDefaultIntervalsAreInfrequent() {
        let config = TapHealthMonitorConfig.default
        XCTAssertGreaterThanOrEqual(config.checkIntervalSeconds, 60)
        XCTAssertGreaterThanOrEqual(config.permissionProbeIntervalSeconds, 300)
        XCTAssertGreaterThanOrEqual(config.inertAfterSeconds, config.startupGraceSeconds)
        XCTAssertGreaterThanOrEqual(config.stalledAfterSeconds, config.inertAfterSeconds)
        XCTAssertGreaterThanOrEqual(config.startupGraceSeconds, 60)
    }

    func testNeverDeliveredInertWhenCreateProbeStillLooksHealthy() {
        let liveness = TapLivenessInput(
            secondsSinceAnchor: 400,
            inertAfterSeconds: 300,
            stalledAfterSeconds: 1800,
            gracePeriodActive: false,
            everReceivedKeyDown: false
        )
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: healthySnapshot(),
            includePermissionProbe: true,
            liveness: liveness
        )
        XCTAssertEqual(TapHealthMonitor.inertKind(liveness), .neverDelivered)
        XCTAssertTrue(issues.contains(.tapInert))
        XCTAssertFalse(issues.contains(.tapDisabled))
        XCTAssertFalse(issues.contains(.listenPermissionLost))
    }

    func testIdleStalledIsSoftInertNotNeverDelivered() {
        let liveness = TapLivenessInput(
            secondsSinceAnchor: 2000,
            inertAfterSeconds: 300,
            stalledAfterSeconds: 1800,
            gracePeriodActive: false,
            everReceivedKeyDown: true
        )
        XCTAssertEqual(TapHealthMonitor.inertKind(liveness), .stalled)
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            inertKind: .stalled,
            consecutiveNeverDeliveredReinstalls: 5,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .reinstall, "idle/stalled must not fatal-exit")
    }

    func testShortSilenceAfterKeyDownsIsNotInert() {
        let liveness = TapLivenessInput(
            secondsSinceAnchor: 400,
            inertAfterSeconds: 300,
            stalledAfterSeconds: 1800,
            gracePeriodActive: false,
            everReceivedKeyDown: true
        )
        XCTAssertNil(TapHealthMonitor.inertKind(liveness))
    }

    func testGracePeriodSuppressesInertDetection() {
        let liveness = TapLivenessInput(
            secondsSinceAnchor: 400,
            inertAfterSeconds: 300,
            stalledAfterSeconds: 1800,
            gracePeriodActive: true,
            everReceivedKeyDown: false
        )
        XCTAssertNil(TapHealthMonitor.inertKind(liveness))
    }

    func testFirstNeverDeliveredActionReinstalls() {
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            inertKind: .neverDelivered,
            consecutiveNeverDeliveredReinstalls: 0,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .reinstall)
    }

    func testRepeatedNeverDeliveredActionExitsSoKeepAliveCanRespawn() {
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            inertKind: .neverDelivered,
            consecutiveNeverDeliveredReinstalls: 1,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .fatalExit)
    }

    func testNonInertIssuesDoNotRequestLivenessExit() {
        let action = TapHealthMonitor.action(
            issues: [.staleTCCSuspected],
            inertKind: nil,
            consecutiveNeverDeliveredReinstalls: 5,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .none)
    }

    private func healthySnapshot() -> PermissionSnapshot {
        PermissionSnapshot(
            axIsProcessTrusted: true,
            listenEventPreflight: true,
            postEventPreflight: true,
            liveTapCreates: true,
            liveTapEnabled: true,
            staleTCCSuspected: false,
            tapCreateAllowed: true,
            readyForInject: true,
            bundleIdentifier: "io.keypop.app",
            executablePath: "/test/keypop",
            hasInputMonitoringUsageDescription: true,
            hasAccessibilityUsageDescription: true
        )
    }
}
