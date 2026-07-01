import Foundation
import TrctlKit
import TrexpandKit
import XCTest

final class SnippetFileWatcherTests: XCTestCase {
    func testReloadsAfterAtomicSnippetWrite() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("trexpand-watch-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let snippetsURL = directory.appendingPathComponent("snippets.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let initial = try KitFormat.encode([Replacement(shortcut: ";a", phrase: "one")])
        try initial.write(to: snippetsURL)

        let reload = expectation(description: "reload")
        reload.expectedFulfillmentCount = 1

        let watcher = SnippetFileWatcher(snippetsPath: snippetsURL.path) {
            reload.fulfill()
        }
        watcher.start()
        defer { watcher.stop() }

        let updated = try KitFormat.encode([Replacement(shortcut: ";a", phrase: "two")])
        try updated.write(to: snippetsURL, options: .atomic)

        wait(for: [reload], timeout: 3.0)
    }
}
