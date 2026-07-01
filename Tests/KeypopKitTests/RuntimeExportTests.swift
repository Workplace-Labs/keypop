import KeypopKit
import XCTest

final class RuntimeExportTests: XCTestCase {
    func testIsEnabledDefaultsToTrue() {
        XCTAssertTrue(RuntimeExport.isEnabled(commandArgs: []))
    }

    func testIsEnabledRespectsNoSyncFlag() {
        XCTAssertFalse(RuntimeExport.isEnabled(commandArgs: ["import", "--no-sync"]))
    }

    func testIsEnabledRespectsDisableEnv() {
        let key = RuntimeExport.disableEnvironmentKey
        let previous = ProcessInfo.processInfo.environment[key]
        defer {
            if let previous {
                setenv(key, previous, 1)
            } else {
                unsetenv(key)
            }
        }

        for value in ["0", "false", "no", "off"] {
            setenv(key, value, 1)
            XCTAssertFalse(RuntimeExport.isEnabled(commandArgs: []), "expected disabled for \(value)")
        }

        setenv(key, "1", 1)
        XCTAssertTrue(RuntimeExport.isEnabled(commandArgs: []))
    }

    func testWriteSnippetKit() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-export-\(UUID().uuidString).json")
        let previous = ProcessInfo.processInfo.environment[RuntimeExport.snippetsPathEnvironmentKey]
        setenv(RuntimeExport.snippetsPathEnvironmentKey, path.path, 1)
        defer {
            if let previous {
                setenv(RuntimeExport.snippetsPathEnvironmentKey, previous, 1)
            } else {
                unsetenv(RuntimeExport.snippetsPathEnvironmentKey)
            }
            try? FileManager.default.removeItem(at: path)
        }

        let rows = [Replacement(shortcut: ";x", phrase: "exported")]
        let written = try RuntimeExport.write(rows)
        XCTAssertEqual(written, path.path)

        let data = try Data(contentsOf: path)
        let parsed = try KitFormat.parseReplacements(from: data)
        XCTAssertEqual(parsed, rows)
    }
}
