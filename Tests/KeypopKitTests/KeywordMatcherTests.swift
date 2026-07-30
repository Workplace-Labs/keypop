import XCTest
@testable import KeypopKit

final class KeywordMatcherTests: XCTestCase {
    func testAdvanceMatchesKeyword() {
        let matcher = KeywordMatcher(keywords: [";wle", ";wlw"])
        var state = ""

        for character in ";wle" {
            let step = matcher.advance(character, from: state)
            state = step.state
            if character == "e" {
                XCTAssertEqual(step.match, ";wle")
            }
        }
    }

    func testWaitsForLongerPrefix() {
        let matcher = KeywordMatcher(keywords: [";wl", ";wle"])
        var state = ""
        for character in ";wl" {
            state = matcher.advance(character, from: state).state
        }
        XCTAssertEqual(state, ";wl")

        let step = matcher.advance("e", from: state)
        XCTAssertEqual(step.match, ";wle")
    }

    func testReportsPrefixCollisions() {
        let collisions = KeywordMatcher.collisions(for: ";wle", among: [";wle", ";wlextract", ";wlmc"])
        XCTAssertEqual(collisions, [KeywordCollision(prefix: ";wle", keyword: ";wlextract")])
    }

    func testReportsAllPrefixCollisionsInSet() {
        let collisions = KeywordMatcher.collisions(among: [";wle", ";wlextract", ";wlmc", ";wlmca"])
        XCTAssertEqual(collisions, [
            KeywordCollision(prefix: ";wle", keyword: ";wlextract"),
            KeywordCollision(prefix: ";wlmc", keyword: ";wlmca")
        ])
    }

    func testNoPartialMatch() {
        let matcher = KeywordMatcher(keywords: [";wle"])
        var state = ""
        for character in ";wl" {
            state = matcher.advance(character, from: state).state
        }
        XCTAssertEqual(state, ";wl")
    }

    func testAdvanceUsesTheUsefulSuffix() {
        let matcher = KeywordMatcher(keywords: [";tcodex", ";mylinkedin"])
        var state = ""
        var match: String?

        for character in "old text;tcodex" {
            let step = matcher.advance(character, from: state)
            state = step.state
            match = step.match ?? match
        }

        XCTAssertEqual(match, ";tcodex")
        XCTAssertEqual(state, "")
    }

    func testControlCharacterCannotPoisonTheNextShortcut() {
        let matcher = KeywordMatcher(keywords: [";tcodex", ";mylinkedin"])
        var state = matcher.advance("\u{3}", from: "").state

        XCTAssertEqual(state, "")

        for character in ";tcodex" {
            let step = matcher.advance(character, from: state)
            state = step.state
            if character == "x" {
                XCTAssertEqual(step.match, ";tcodex")
            }
        }
    }

    func testIncompleteCandidateSurvivesUnrelatedPrefix() {
        let matcher = KeywordMatcher(keywords: [";tcodex"])
        var state = ""

        for character in "abc;tc" {
            state = matcher.advance(character, from: state).state
        }

        XCTAssertEqual(state, ";tc")
    }

    func testNewShortcutCanStartAfterStaleCandidateText() {
        let matcher = KeywordMatcher(keywords: [";tcodex"])
        var state = "stale"

        for character in ";tcodex" {
            let step = matcher.advance(character, from: state)
            state = step.state
            if character == "x" {
                XCTAssertEqual(step.match, ";tcodex")
            }
        }
    }
}
