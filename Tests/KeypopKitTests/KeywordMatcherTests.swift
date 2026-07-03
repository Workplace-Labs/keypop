import XCTest
@testable import KeypopKit

final class KeywordMatcherTests: XCTestCase {
    func testExactMatch() {
        let matcher = KeywordMatcher(keywords: [";wle", ";wlw"])
        XCTAssertEqual(matcher.match(in: ";wle"), ";wle")
    }

    func testWaitsForLongerPrefix() {
        let matcher = KeywordMatcher(keywords: [";wl", ";wle"])
        XCTAssertNil(matcher.match(in: ";wl"))
        XCTAssertEqual(matcher.match(in: ";wle"), ";wle")
    }

    func testReportsPrefixCollisions() {
        let collisions = KeywordMatcher.collisions(for: ";wle", among: [";wle", ";wlextract", ";wlmc"])
        XCTAssertEqual(collisions, [KeywordCollision(keyword: ";wle", collidesWith: ";wlextract")])
    }

    func testNoPartialMatch() {
        let matcher = KeywordMatcher(keywords: [";wle"])
        XCTAssertNil(matcher.match(in: ";wl"))
    }

    func testBufferResetOnWhitespace() {
        let matcher = KeywordMatcher(keywords: [";wle"])
        XCTAssertTrue(matcher.shouldResetBuffer(for: " "))
        XCTAssertFalse(matcher.shouldResetBuffer(for: ";"))
    }
}
