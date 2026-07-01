import TrctlKit
import XCTest

final class ExpanderExportTests: XCTestCase {
    func testIsEnabledDefaultsToTrue() {
        XCTAssertTrue(ExpanderExport.isEnabled(commandArgs: []))
    }

    func testIsEnabledRespectsNoSyncFlag() {
        XCTAssertFalse(ExpanderExport.isEnabled(commandArgs: ["import", "--no-sync-expander"]))
    }

    func testIsEnabledRespectsDisableEnv() {
        let key = ExpanderExport.disableEnvironmentKey
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
            XCTAssertFalse(ExpanderExport.isEnabled(commandArgs: []), "expected disabled for \(value)")
        }

        setenv(key, "1", 1)
        XCTAssertTrue(ExpanderExport.isEnabled(commandArgs: []))
    }

    func testWriteSnippetKit() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("expander-export-\(UUID().uuidString).json")
        let previous = ProcessInfo.processInfo.environment[ExpanderExport.snippetsPathEnvironmentKey]
        setenv(ExpanderExport.snippetsPathEnvironmentKey, path.path, 1)
        defer {
            if let previous {
                setenv(ExpanderExport.snippetsPathEnvironmentKey, previous, 1)
            } else {
                unsetenv(ExpanderExport.snippetsPathEnvironmentKey)
            }
            try? FileManager.default.removeItem(at: path)
        }

        let rows = [Replacement(shortcut: ";x", phrase: "exported")]
        let written = try ExpanderExport.write(rows)
        XCTAssertEqual(written, path.path)

        let data = try Data(contentsOf: path)
        let parsed = try KitFormat.parseReplacements(from: data)
        XCTAssertEqual(parsed, rows)
    }
}
