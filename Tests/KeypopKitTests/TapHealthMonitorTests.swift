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
            staleAxCacheSuspected: false,
            readyForListen: true,
            readyForInject: true
        )
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: false,
            snapshot: snapshot,
            includePermissionProbe: false
        )
        XCTAssertEqual(issues, [.tapDisabled])
    }

    func testPermissionProbeFindsStaleCache() {
        let snapshot = PermissionSnapshot(
            axIsProcessTrusted: true,
            listenEventPreflight: true,
            postEventPreflight: true,
            liveTapCreates: false,
            liveTapEnabled: false,
            staleAxCacheSuspected: true,
            readyForListen: false,
            readyForInject: true
        )
        let issues = TapHealthMonitor.evaluate(
            tapEnabled: true,
            snapshot: snapshot,
            includePermissionProbe: true
        )
        XCTAssertTrue(issues.contains(.listenPermissionLost))
        XCTAssertTrue(issues.contains(.staleAxCacheSuspected))
    }

    func testDefaultIntervalsAreInfrequent() {
        let config = TapHealthMonitorConfig.default
        XCTAssertGreaterThanOrEqual(config.checkIntervalSeconds, 60)
        XCTAssertGreaterThanOrEqual(config.permissionProbeIntervalSeconds, 300)
    }
}
