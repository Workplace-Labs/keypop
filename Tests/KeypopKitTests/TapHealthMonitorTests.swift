import XCTest
@testable import KeypopKit

final class TapHealthMonitorTests: XCTestCase {
    func testTapDisabledOnlyOnLightCheck() {
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: false,
            snapshot: healthySnapshot(),
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
            readyForListen: false,
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

    func testEnabledTapWithCreateProbeStillReportsInertWithoutKeyEvents() {
        // The production failure mode: tapCreate works, tapIsEnabled is true,
        // but the callback never receives keyDowns.
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: healthySnapshot(),
            includePermissionProbe: true,
            liveness: TapLivenessInput(
                secondsSinceLastKeyDown: 400,
                inertAfterSeconds: 300,
                gracePeriodActive: false
            )
        )
        XCTAssertTrue(issues.contains(.tapInert), "health must detect inert taps that still look enabled")
        XCTAssertFalse(issues.contains(.tapDisabled))
        XCTAssertFalse(issues.contains(.listenPermissionLost))
    }

    func testGracePeriodSuppressesInertDetection() {
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: healthySnapshot(),
            includePermissionProbe: false,
            liveness: TapLivenessInput(
                secondsSinceLastKeyDown: 400,
                inertAfterSeconds: 300,
                gracePeriodActive: true
            )
        )
        XCTAssertFalse(issues.contains(.tapInert))
    }

    func testRecentKeyDownsClearInertDetection() {
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: healthySnapshot(),
            includePermissionProbe: false,
            liveness: TapLivenessInput(
                secondsSinceLastKeyDown: 5,
                inertAfterSeconds: 300,
                gracePeriodActive: false
            )
        )
        XCTAssertFalse(issues.contains(.tapInert))
    }

    func testFirstInertActionReinstalls() {
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            consecutiveInertReinstalls: 0,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .reinstall)
    }

    func testRepeatedInertActionExitsSoKeepAliveCanRespawn() {
        let action = TapHealthMonitor.action(
            issues: [.tapInert],
            consecutiveInertReinstalls: 1,
            maxInertReinstallsBeforeExit: 1
        )
        XCTAssertEqual(action, .fatalExit)
    }

    func testNonInertIssuesDoNotRequestLivenessExit() {
        let action = TapHealthMonitor.action(
            issues: [.staleTCCSuspected],
            consecutiveInertReinstalls: 5,
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
            readyForListen: true,
            readyForInject: true,
            bundleIdentifier: "io.keypop.app",
            executablePath: "/test/keypop",
            hasInputMonitoringUsageDescription: true,
            hasAccessibilityUsageDescription: true
        )
    }
}
