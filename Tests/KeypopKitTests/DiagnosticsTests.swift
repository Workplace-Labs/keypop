import XCTest
@testable import KeypopKit

final class DiagnosticsTests: XCTestCase {
    func testDiagnosticSessionRequiresFutureOptInExpiry() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertFalse(DiagnosticSession(environment: [:], now: now).isEnabled)
        XCTAssertFalse(DiagnosticSession(environment: [
            DiagnosticSession.enabledKey: "1",
            DiagnosticSession.expiresAtKey: "999",
        ], now: now).isEnabled)
        XCTAssertTrue(DiagnosticSession(environment: [
            DiagnosticSession.enabledKey: "1",
            DiagnosticSession.expiresAtKey: "1001",
        ], now: now).isEnabled)
    }

    func testRecordLineIsStructuredAndSanitizesSeparators() {
        let line = KeypopDiagnostics.recordLine("inject", fields: [
            "stage": "paste_posted",
            "target": "com.example|app\nname",
        ])

        XCTAssertEqual(line, "diagnostic|inject|stage=paste_posted|target=com.example_app_name")
    }

    func testRecordLineDoesNotRequireSensitivePayloads() {
        let line = KeypopDiagnostics.recordLine("match", fields: [
            "keyword_length": "7",
            "phrase_length": "82",
        ])

        XCTAssertFalse(line.contains(";pproof"))
        XCTAssertFalse(line.contains("Proofread"))
    }

    func testDiagnosticSessionExpiresAtRuntime() {
        let session = DiagnosticSession(environment: [
            DiagnosticSession.enabledKey: "1",
            DiagnosticSession.expiresAtKey: "1001",
        ])

        XCTAssertNotNil(session.expiresAt)
        XCTAssertFalse(session.isEnabled)
    }
}
