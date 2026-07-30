import Foundation
import XCTest
@testable import KeypopKit

final class SnippetFileWatcherTests: XCTestCase {
    func testReloadsAfterAtomicSnippetWrite() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snippetsURL = directory.appendingPathComponent("snippets.json")

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

    func testSiblingFileWriteDoesNotReloadSnippets() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snippetsURL = directory.appendingPathComponent("snippets.json")
        let usageURL = directory.appendingPathComponent("usage.json")

        let initial = try KitFormat.encode([Replacement(shortcut: ";a", phrase: "one")])
        try initial.write(to: snippetsURL)

        let reload = expectation(description: "unexpected reload")
        reload.isInverted = true

        let watcher = SnippetFileWatcher(snippetsPath: snippetsURL.path) {
            reload.fulfill()
        }
        watcher.start()
        defer { watcher.stop() }

        try Data(#"{";a":{"count":1,"lastUsedAt":"1970-01-01T00:00:00Z"}}"#.utf8)
            .write(to: usageURL, options: .atomic)

        wait(for: [reload], timeout: 1.0)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-watch-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
