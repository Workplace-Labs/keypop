import ApplicationServices
import XCTest
@testable import KeypopKit

final class ClipboardInjectorTests: XCTestCase {
    func testDefaultRestoreDelayIsLongEnoughForSlowPasteConsumers() {
        XCTAssertGreaterThanOrEqual(ClipboardInjector.defaultRestoreDelayMs, 500)
        XCTAssertEqual(ClipboardInjector().restoreDelayMs, ClipboardInjector.defaultRestoreDelayMs)
    }

    func testInjectSchedulesRestoreInsteadOfBlockingForRestoreDelay() throws {
        guard CGPreflightPostEventAccess() else {
            throw XCTSkip("Accessibility/PostEvent not granted in this test environment")
        }

        final class Capture: @unchecked Sendable {
            var scheduledDelay: UInt32?
            var restoreWork: (@Sendable () -> Void)?
        }
        let capture = Capture()
        let injector = ClipboardInjector(restoreDelayMs: 750) { delay, work in
            capture.scheduledDelay = delay
            capture.restoreWork = work
        }

        let started = Date()
        try injector.inject("keypop-restore-policy-test")
        let elapsed = Date().timeIntervalSince(started)

        XCTAssertEqual(capture.scheduledDelay, 750)
        XCTAssertNotNil(capture.restoreWork)
        XCTAssertLessThan(elapsed, 0.2, "inject must not usleep for the restore delay on the caller thread")
    }
}

