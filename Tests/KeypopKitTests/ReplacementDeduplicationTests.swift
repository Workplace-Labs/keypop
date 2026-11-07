import KeypopKit
import XCTest

final class ReplacementDeduplicationTests: XCTestCase {
    func testDeduplicateKeepsLastPhraseForSameShortcut() {
        let rows = [
            Replacement(shortcut: ";a", phrase: "first"),
            Replacement(shortcut: ";a", phrase: "second"),
            Replacement(shortcut: ";b", phrase: "other"),
        ]
        let (deduplicated, warnings) = ReplacementDeduplication.deduplicate(rows)

        XCTAssertEqual(deduplicated.count, 2)
        XCTAssertEqual(deduplicated[0].shortcut, ";a")
        XCTAssertEqual(deduplicated[0].phrase, "second")
        XCTAssertEqual(deduplicated[1].shortcut, ";b")
        XCTAssertEqual(deduplicated[1].phrase, "other")

        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(warnings[0].shortcut, ";a")
        XCTAssertEqual(warnings[0].keptPhrase, "second")
        XCTAssertEqual(warnings[0].droppedPhrases, ["first"])
    }

    func testDeduplicateLeavesSingleShortcutUnchanged() {
        let rows = [Replacement(shortcut: ";solo", phrase: "only")]
        let (deduplicated, warnings) = ReplacementDeduplication.deduplicate(rows)

        XCTAssertEqual(deduplicated, rows)
        XCTAssertTrue(warnings.isEmpty)
    }

    func testDeduplicateLeavesDistinctShortcutsUnchanged() {
        let rows = [
            Replacement(shortcut: ";one", phrase: "alpha"),
            Replacement(shortcut: ";two", phrase: "beta"),
        ]
        let (deduplicated, warnings) = ReplacementDeduplication.deduplicate(rows)

        XCTAssertEqual(deduplicated, rows)
        XCTAssertTrue(warnings.isEmpty)
    }
}
