import XCTest
@testable import Luca_Debug

class PrivateMeetingSelfCheckinTests: XCTestCase {
    private static let WEB_APP_URL = "https://app.luca-app.de/webapp"
    private static let PRIVATE_MEETING = "meeting"
    private static let SCANNER_ID = "81d9e1db-7050-4557-b1ca-a9e4fe899bd9"
    private static let LUCA_DATA = "eyJsbiI6IkMiLCJmbiI6IkMifQ"

    /// Private Meeting Checkin
    private static let CHECK_IN_URL_STRING = WEB_APP_URL + "/" + PRIVATE_MEETING + "/" + SCANNER_ID + "#" + LUCA_DATA
    private static let CHECK_IN_URL = URL(string: CHECK_IN_URL_STRING)!

    func testPrivateMeetingSelfCheckinWithLucaData_isNotNil() throws {
        let selfCheckin = PrivateMeetingSelfCheckin(urlToParse: PrivateMeetingSelfCheckinTests.CHECK_IN_URL)
        XCTAssertNotNil(selfCheckin, "Private Meeting Self Checkin should not be nil for input \(PrivateMeetingSelfCheckinTests.CHECK_IN_URL)")
    }

    func testPrivateMeetingSelfCheckinWithLucaData_scannerIdIsCorrect() throws {
        let selfCheckin = PrivateMeetingSelfCheckin(urlToParse: PrivateMeetingSelfCheckinTests.CHECK_IN_URL)
        XCTAssertEqual(selfCheckin!.scannerId, PrivateMeetingSelfCheckinTests.SCANNER_ID, "Parsed scanner id should be equal to \(PrivateMeetingSelfCheckinTests.SCANNER_ID), but is not")
    }

    func testPrivateMeetingSelfCheckinWithLucaData_additionalDataHasFn() throws {
        let selfCheckin = PrivateMeetingSelfCheckin(urlToParse: PrivateMeetingSelfCheckinTests.CHECK_IN_URL)
        XCTAssertNotNil(selfCheckin!.additionalData.fn, "Parsed fn from additionalData should not be nil")
    }

    func testPrivateMeetingSelfCheckinWithLucaData_additionalDataHasLn() throws {
        let selfCheckin = PrivateMeetingSelfCheckin(urlToParse: PrivateMeetingSelfCheckinTests.CHECK_IN_URL)
        XCTAssertNotNil(selfCheckin!.additionalData.ln, "Parsed ln from additionalData should not be nil")
    }
}
