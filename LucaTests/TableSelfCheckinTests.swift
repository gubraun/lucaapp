import XCTest
@testable import Luca_Debug

class TableSelfCheckinTests: XCTestCase {
    private static let WEB_APP_URL = "https://app.luca-app.de/webapp"
    private static let SCANNER_ID = "81d9e1db-7050-4557-b1ca-a9e4fe899bd9"
    private static let LUCA_DATA = "eyJ0YWJsZSI6N30"
    // swiftlint:disable:next line_length
    private static let CWA_URL_SUFFIX = "/CWA1/CAESLAgBEhNEb2xvcmVzIGN1bHBhIHV0IHNpGhNOb3N0cnVkIE5hbSBpZCBlbGlnGnYIARJggwLMzE153tQwAOf2MZoUXXfzWTdlSpfS99iZffmcmxOG9njSK4RTimFOFwDh6t0Tyw8XR01ugDYjtuKwjjuK49Oh83FWct6XpefPi9Skjxvvz53i9gaMmUEc96pbtoaAGhDL1rYQOi3Bh_YYps7XagWYIgcIARAIGIQF"

    /// Table Checkin
    private static let CHECK_IN_URL_STRING = WEB_APP_URL + "/" + SCANNER_ID + "#" + LUCA_DATA
    private static let CHECK_IN_URL = URL(string: CHECK_IN_URL_STRING)!
    private static let CHECK_IN_URL_STRING_WITH_CWA_DATA = CHECK_IN_URL_STRING + CWA_URL_SUFFIX
    private static let CHECK_IN_URL_WITH_CWA_DATA = URL(string: CHECK_IN_URL_STRING_WITH_CWA_DATA)!

    func testTableSelfCheckinWithLucaData_isNotNil() throws {
        let selfCheckin = TableSelfCheckin(urlToParse: TableSelfCheckinTests.CHECK_IN_URL)
        XCTAssertNotNil(selfCheckin, "Table Self Checkin should not be nil for input \(TableSelfCheckinTests.CHECK_IN_URL)")
    }

    func testTableSelfCheckinWithLucaData_scannerIdIsCorrect() throws {
        let selfCheckin = TableSelfCheckin(urlToParse: TableSelfCheckinTests.CHECK_IN_URL)
        XCTAssertEqual(selfCheckin!.scannerId, TableSelfCheckinTests.SCANNER_ID, "Parsed scanner id should be equal to \(TableSelfCheckinTests.SCANNER_ID), but is not")
    }

    func testTableSelfCheckinWithLucaData_tableNumberIsNotNil() throws {
        let selfCheckin = TableSelfCheckin(urlToParse: TableSelfCheckinTests.CHECK_IN_URL)
        XCTAssertNotNil(selfCheckin!.additionalData?.table, "Parsed table number should not be nil")
    }

    func testTableSelfCheckinWithCWAData_isNotNil() throws {
        let selfCheckin = TableSelfCheckin(urlToParse: TableSelfCheckinTests.CHECK_IN_URL_WITH_CWA_DATA)
        XCTAssertNotNil(selfCheckin, "Table Self Checkin should not be nil for input \(TableSelfCheckinTests.CHECK_IN_URL_WITH_CWA_DATA)")
    }

    func testTableSelfCheckinWithCWAData_scannerIdIsCorrect() throws {
        let selfCheckin = TableSelfCheckin(urlToParse: TableSelfCheckinTests.CHECK_IN_URL_WITH_CWA_DATA)
        XCTAssertEqual(selfCheckin!.scannerId, TableSelfCheckinTests.SCANNER_ID, "Parsed scanner id should be equal to \(TableSelfCheckinTests.SCANNER_ID), but is not")
    }

    func testTableSelfCheckinWithCWAData_tableNumberIsNotNil() throws {
        let selfCheckin = TableSelfCheckin(urlToParse: TableSelfCheckinTests.CHECK_IN_URL_WITH_CWA_DATA)
        XCTAssertNotNil(selfCheckin!.additionalData?.table, "Parsed table number should not be nil")
    }
}
