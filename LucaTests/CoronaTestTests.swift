import XCTest
@testable import Luca

class CoronaTestTests: XCTestCase {
    let christianFrankeTest = CoronaTest(version: 2,
                                         name: "d8973041e35eda9e716d3e2fed54045e913ebba438ba6bd8309e84f857fa739c",
                                         time: Int(Date().timeIntervalSince1970 - TimeInterval(50).to(.hour)),
                                         category: .f,
                                         result: .n,
                                         lab: "Covimedical GmbH",
                                         doctor: "Prof. Dr. Coronafight")

    let bjorkTest = CoronaTest(version: 2,
                               name: "fadca6f1af6c8c84f5c24adf22bf2490d9679e3fba27b8715b83d33f9f90f3af",
                               time: Int(Date().timeIntervalSince1970),
                               category: .f,
                               result: .n,
                               lab: "Covimedical GmbH",
                               doctor: "Prof. Dr. Coronafight")

    // MARK: - Name validation
    func test_belongsToUser_returnsTrueForValidUser() {
        let validFirstName = "Christian"
        let validLastName = "Franke"

        let belongsToUser = christianFrankeTest.belongsToUser(withFirstName: validFirstName, lastName: validLastName)
        XCTAssertTrue(belongsToUser)
    }

    func test_belongsToUser_returnsFalseForInvalidUser() {
        let invalidFirstName = "Martin"
        let invalidLastName = "Meier"

        let belongsToUser = christianFrankeTest.belongsToUser(withFirstName: invalidFirstName, lastName: invalidLastName)
        XCTAssertFalse(belongsToUser)
    }

    func test_belongsToUser_returnsTrueForValidUserWithLowercaseName() {
        let validFirstName = "christian"
        let validLastName = "franke"

        let belongsToUser = christianFrankeTest.belongsToUser(withFirstName: validFirstName, lastName: validLastName)
        XCTAssertTrue(belongsToUser)
    }

    func test_belongsToUser_returnsTrueForValidUserWithNonAsciiCharInName() {
        let validFirstName = "Björk"
        let validLastName = "Guðmundsdóttir"

        let belongsToUser = bjorkTest.belongsToUser(withFirstName: validFirstName, lastName: validLastName)
        XCTAssertTrue(belongsToUser)
    }

    // MARK: - Time validation
    func test_isValid_returnsTrueForTestFromToday() {
        XCTAssertTrue(bjorkTest.isValid)
    }

    func test_isValid_returnsFalseForTestOlderThan48h() {
        XCTAssertFalse(christianFrankeTest.isValid)
    }
}
