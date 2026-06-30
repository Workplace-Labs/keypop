import KSPrivateBridge
import XCTest

final class KSPrivateBridgeTests: XCTestCase {
    func testKeyboardServicesClassesAreDiscoverable() throws {
        let inspection = KSProbeInspect()

        XCTAssertEqual(inspection["loaded"] as? Bool, true)

        let classes = try XCTUnwrap(inspection["classes"] as? [String: Bool])
        XCTAssertEqual(classes["_KSTextReplacementClientStore"], true)
        XCTAssertEqual(classes["_KSTextReplacementEntry"], true)
        XCTAssertEqual(classes["_KSTextReplacementHelper"], true)
    }

    func testReadSourceProbeReturnsCounts() throws {
        var error: NSError?
        let sources = KSProbeReadSources(&error)

        XCTAssertNil(error)
        XCTAssertNotNil(sources["textReplacementEntriesCount"])
        XCTAssertNotNil(sources["queryTextReplacementsWithCallbackCount"])
        XCTAssertNotNil(sources["coreDataStoreCount"])
        XCTAssertNotNil(sources["legacyDefaultsCount"])
    }
}
