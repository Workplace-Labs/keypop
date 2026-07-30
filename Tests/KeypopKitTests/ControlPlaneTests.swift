import XCTest
@testable import KeypopKit

final class ControlPlaneTests: XCTestCase {
    func testRequestAndConsumeHeal() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-control-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let key = ControlPlane.controlDirectoryEnvironmentKey
        let previous = ProcessInfo.processInfo.environment[key]
        defer {
            if let previous {
                setenv(key, previous, 1)
            } else {
                unsetenv(key)
            }
        }
        setenv(key, directory.path, 1)

        XCTAssertFalse(ControlPlane.healRequestPending())
        try ControlPlane.requestHeal(reason: "unit-test")
        XCTAssertTrue(ControlPlane.healRequestPending())

        let reason = ControlPlane.consumeHealRequest()
        XCTAssertEqual(reason, "unit-test")
        XCTAssertFalse(ControlPlane.healRequestPending())
        XCTAssertNil(ControlPlane.consumeHealRequest())
    }

    func testBuiltInFixKeywordWinsOverUserPhrase() {
        let merged = BuiltInSnippets.merging(with: [
            BuiltInSnippets.fixKeyword: "user override",
            ";pproof": "proof",
        ])
        XCTAssertEqual(merged[BuiltInSnippets.fixKeyword], BuiltInSnippets.fixPhrase)
        XCTAssertEqual(merged[";pproof"], "proof")
    }
}
