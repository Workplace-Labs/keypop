import ApplicationServices
import XCTest
@testable import KeypopKit

final class RuntimeInputClassifierTests: XCTestCase {
    func testControlCResetsTheMatcher() {
        XCTAssertEqual(
            RuntimeInputClassifier.classify(keyCode: 0x08, flags: .maskControl, unicode: "\u{3}"),
            .reset
        )
    }

    func testEditingAndWhitespaceResetTheMatcher() {
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x33, flags: [], unicode: ""), .reset)
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x31, flags: [], unicode: " "), .reset)
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x24, flags: [], unicode: "\n"), .reset)
    }

    func testPlainTextAndShiftedTextAreMatchable() {
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x29, flags: [], unicode: ";"), .text(";"))
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x00, flags: .maskShift, unicode: "A"), .text("A"))
    }

    func testEmptyAndMultiCharacterInputResetTheMatcher() {
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x00, flags: [], unicode: ""), .reset)
        XCTAssertEqual(RuntimeInputClassifier.classify(keyCode: 0x00, flags: [], unicode: "ab"), .reset)
    }
}
