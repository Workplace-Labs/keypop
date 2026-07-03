import XCTest
@testable import KeypopKit

final class TapHealthMonitorTests: XCTestCase {
    func testTapDisabledOnlyOnLightCheck() {
        let snapshot = PermissionSnapshot(
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
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: false,
            snapshot: snapshot,
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
    }
}
