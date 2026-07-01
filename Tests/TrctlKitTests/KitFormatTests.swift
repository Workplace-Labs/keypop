import TrctlKit
import XCTest

final class KitFormatTests: XCTestCase {
    func testParseSnippetKit() throws {
        let json = """
        [
          {
            "name": "Prompt / Code review",
            "keyword": ";pcr",
            "text": "Review this code."
          }
        ]
        """.data(using: .utf8)!

        let rows = try KitFormat.parseReplacements(from: json)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].shortcut, ";pcr")
        XCTAssertEqual(rows[0].phrase, "Review this code.")
    }

    func testLegacyShortcutPhraseFormatRejected() {
        let json = """
        [
          {
            "shortcut": ";ace",
            "phrase": "user@example.com"
          }
        ]
        """.data(using: .utf8)!

        XCTAssertThrowsError(try KitFormat.parseReplacements(from: json)) { error in
            XCTAssertTrue("\(error)".contains("snippet"))
        }
    }

    func testExportRoundTrip() throws {
        let original = [Replacement(shortcut: ";pcr", phrase: "Review this.")]
        let data = try KitFormat.encode(original)
        let parsed = try KitFormat.parseReplacements(from: data)
        XCTAssertEqual(parsed, original)
    }

    func testDefaultNameStripsSemicolonPrefix() {
        XCTAssertEqual(SnippetEntry.defaultName(for: ";ace"), "Ace")
        XCTAssertEqual(SnippetEntry.defaultName(for: "omw"), "Omw")
        XCTAssertEqual(SnippetEntry.defaultName(for: ";pcr"), "Pcr")
    }

    func testMissingKeywordFails() {
        let json = """
        [{ "name": "Broken", "keyword": "", "text": "No keyword" }]
        """.data(using: .utf8)!

        XCTAssertThrowsError(try KitFormat.parseReplacements(from: json)) { error in
            XCTAssertTrue("\(error)".contains("keyword"))
        }
    }
}
