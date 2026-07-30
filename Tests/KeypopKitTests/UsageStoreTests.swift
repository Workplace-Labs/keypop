import XCTest
@testable import KeypopKit

final class UsageStoreTests: XCTestCase {
    func testDefaultPathRespectsEnvironmentOverride() {
        let key = UsageStore.usagePathEnvironmentKey
        let previous = ProcessInfo.processInfo.environment[key]
        defer {
            if let previous {
                setenv(key, previous, 1)
            } else {
                unsetenv(key)
            }
        }

        setenv(key, "/tmp/keypop-usage-test.json", 1)
        XCTAssertEqual(UsageStore.defaultPath, "/tmp/keypop-usage-test.json")
    }

    func testDefaultPathIsOutsideSnippetWatchDirectory() {
        let key = UsageStore.usagePathEnvironmentKey
        let previous = ProcessInfo.processInfo.environment[key]
        defer {
            if let previous {
                setenv(key, previous, 1)
            } else {
                unsetenv(key)
            }
        }
        unsetenv(key)

        let path = UsageStore.defaultPath
        XCTAssertFalse(
            path.contains("/.config/keypop/usage.json"),
            "usage writes must not live beside snippets.json (directory watch false reloads)"
        )
        XCTAssertTrue(path.contains("/keypop/"), "usage path should stay under a keypop-owned directory")
        XCTAssertTrue(path.hasSuffix("usage.json"))
        XCTAssertNotEqual(path, UsageStore.legacyDefaultPath)
    }

    func testMigratesLegacyUsageFileOnce() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-usage-migrate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let legacy = root.appendingPathComponent("legacy-usage.json")
        let modern = root.appendingPathComponent("state/usage.json")
        let payload = Data(#"{";wlmc":{"count":2,"lastUsedAt":"1970-01-01T00:01:00Z"}}"#.utf8)
        try payload.write(to: legacy)

        UsageStore.migrateIfNeeded(from: legacy.path, to: modern.path, fileManager: .default)

        let store = UsageStore(path: modern.path)
        XCTAssertEqual(
            try store.records(),
            [";wlmc": UsageRecord(count: 2, lastUsedAt: "1970-01-01T00:01:00Z")]
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacy.path))
    }

    func testRecordUseIncrementsCountAndTimestamp() throws {
        let path = temporaryUsagePath()
        defer { try? FileManager.default.removeItem(at: path) }

        let store = UsageStore(path: path.path)
        try store.recordUse(keyword: ";wlmc", at: Date(timeIntervalSince1970: 0))
        try store.recordUse(keyword: ";wlmc", at: Date(timeIntervalSince1970: 60))

        XCTAssertEqual(
            try store.records(),
            [";wlmc": UsageRecord(count: 2, lastUsedAt: "1970-01-01T00:01:00Z")]
        )
    }

    func testRecordsFiltersByPrefix() throws {
        let path = temporaryUsagePath()
        defer { try? FileManager.default.removeItem(at: path) }

        let store = UsageStore(path: path.path)
        try store.recordUse(keyword: ";wlmc", at: Date(timeIntervalSince1970: 0))
        try store.recordUse(keyword: ";pcr", at: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(Array(try store.records(prefix: ";wl").keys), [";wlmc"])
    }

    func testResetCanClearOneKeywordOrAllKeywords() throws {
        let path = temporaryUsagePath()
        defer { try? FileManager.default.removeItem(at: path) }

        let store = UsageStore(path: path.path)
        try store.recordUse(keyword: ";wlmc", at: Date(timeIntervalSince1970: 0))
        try store.recordUse(keyword: ";pcr", at: Date(timeIntervalSince1970: 0))

        try store.reset(keyword: ";wlmc")
        XCTAssertEqual(Set(try store.records().keys), [";pcr"])

        try store.reset()
        XCTAssertEqual(try store.records(), [:])
    }

    private func temporaryUsagePath() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-usage-\(UUID().uuidString).json")
    }
}
