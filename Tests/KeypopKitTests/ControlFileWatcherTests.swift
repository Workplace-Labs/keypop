import Foundation
import XCTest
@testable import KeypopKit

final class ControlFileWatcherTests: XCTestCase {
    func testHealRequestInvokesCallback() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-control-watch-\(UUID().uuidString)", isDirectory: true)
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

        let healed = expectation(description: "heal")
        var seenReason: String?
        let watcher = ControlFileWatcher(directoryPath: directory.path) { reason in
            seenReason = reason
            healed.fulfill()
        }
        watcher.start()
        defer { watcher.stop() }

        try ControlPlane.requestHeal(reason: "watcher-test")
        wait(for: [healed], timeout: 3.0)
        XCTAssertEqual(seenReason, "watcher-test")
        XCTAssertFalse(ControlPlane.healRequestPending())
    }
}
