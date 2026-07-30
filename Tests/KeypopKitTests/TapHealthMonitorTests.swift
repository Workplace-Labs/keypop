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
        XCTAssertGreaterThanOrEqual(config.startupGraceSeconds, 60)
    }

    func testNeverDeliveredInertWhenCreateProbeStillLooksHealthy() {
        let liveness = TapLivenessInput(
            secondsSinceInstall: 400,
            inertAfterSeconds: 300,
            gracePeriodActive: false,
            everReceivedKeyDown: false
        )
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: healthySnapshot(),
            includePermissionProbe: true,
            liveness: liveness
        )
        XCTAssertTrue(TapHealthMonitor.isNeverDelivered(liveness))
        XCTAssertTrue(issues.contains(.tapInert))
    }

    func testIdleAfterPriorKeyDownsIsNotInert() {
        let liveness = TapLivenessInput(
            secondsSinceInstall: 10_000,
            inertAfterSeconds: 300,
            gracePeriodActive: false,
            everReceivedKeyDown: true
        )
        XCTAssertFalse(TapHealthMonitor.isNeverDelivered(liveness))
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            includePermissionProbe: false,
            liveness: liveness
        )
        XCTAssertFalse(issues.contains(.tapInert))
    }

    func testGracePeriodSuppressesInertDetection() {
        let liveness = TapLivenessInput(
            secondsSinceInstall: 400,
            inertAfterSeconds: 300,
            gracePeriodActive: true,
            everReceivedKeyDown: false
        )
        XCTAssertFalse(TapHealthMonitor.isNeverDelivered(liveness))
    }

    func testFirstNeverDeliveredActionReinstalls() {
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            consecutiveNeverDeliveredReinstalls: 0,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .reinstall)
    }

    func testRepeatedNeverDeliveredActionExitsSoKeepAliveCanRespawn() {
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            consecutiveNeverDeliveredReinstalls: 1,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .fatalExit)
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
