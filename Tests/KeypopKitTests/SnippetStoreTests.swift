import XCTest
@testable import KeypopKit

final class SnippetStoreTests: XCTestCase {
    func testLoadSnippetKit() throws {
        let json = """
        [
          {"name": "Test", "keyword": ";t", "text": "hello"}
        ]
        """.data(using: .utf8)!

        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-test-\(UUID().uuidString).json")
        try json.write(to: path)
        defer { try? FileManager.default.removeItem(at: path) }

        let store = try SnippetStore.load(from: path.path)
        XCTAssertEqual(store.phrases[";t"], "hello")
    }

    func testLoadKeepsLastPhraseForDuplicateKeywords() throws {
        let json = """
        [
          {"name": "Old", "keyword": ";dup", "text": "old"},
          {"name": "New", "keyword": ";dup", "text": "new"}
        ]
        """.data(using: .utf8)!

        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("keypop-test-\(UUID().uuidString).json")
        try json.write(to: path)
        defer { try? FileManager.default.removeItem(at: path) }

        let store = try SnippetStore.load(from: path.path)
        XCTAssertEqual(store.phrases[";dup"], "new")
        XCTAssertEqual(store.phrases.count, 1)
    }
}
