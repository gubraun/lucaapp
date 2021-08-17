import RxTest
import RxSwift
import XCTest
@testable import Luca_Debug

class UserOrChildValidatorTests: XCTestCase {

    var scheduler: TestScheduler!
    var childrenValidator: DocumentValidator!

    let child1 = Person(firstName: "Child1", lastName: "Childmann")
    let child2 = Person(firstName: "Child2", lastName: "Childmann")
    let child3 = Person(firstName: "Child3", lastName: "Kowalski")

    let userFirstname = "Hans"
    let userLastname = "Zimmermann"

    override func setUpWithError() throws {
        scheduler = TestScheduler(initialClock: 0)

        let userIdentityValidator = DocumentOwnershipValidator(firstNameSource: Single.just(userFirstname), lastNameSource: Single.just(userLastname))
        childrenValidator = UserOrChildValidator(
            userIdentityValidator: userIdentityValidator,
            personsSource: Single.just([child1, child2, child3])
        )
    }

    func test_noNameMatchesAgeBelow14_fail() {

        guard let birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let document = DocumentWithIdentityAndBirthday(dateOfBirth: birthday, firstName: "Name that", lastName: "Doesn't match")

        let validation = scheduler.createObserver(Never.self)
        _ = childrenValidator.validate(document: document)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.nameValidationFailed)])
    }

    func test_noNameMatchesAgeAbove14_fail() {

        guard let birthday = Calendar.current.date(byAdding: .year, value: -18, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let document = DocumentWithIdentityAndBirthday(dateOfBirth: birthday, firstName: "Name that", lastName: "Doesn't match")

        let validation = scheduler.createObserver(Never.self)
        _ = childrenValidator.validate(document: document)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.invalidChildAge)])
    }

    func test_usersNameMatches_success() {

        guard let birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let document = DocumentWithIdentityAndBirthday(dateOfBirth: birthday, firstName: userFirstname, lastName: userLastname)

        let validation = scheduler.createObserver(Never.self)
        _ = childrenValidator.validate(document: document)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

    func test_childMatchesButAgeTooHigh_fail() {

        guard let birthday = Calendar.current.date(byAdding: .year, value: -18, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let document = DocumentWithIdentityAndBirthday(dateOfBirth: birthday, firstName: child2.firstName, lastName: child2.lastName)

        let validation = scheduler.createObserver(Never.self)
        _ = childrenValidator.validate(document: document)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.invalidChildAge)])
    }

    func test_childAndAgeMatch_success() {

        guard let birthday = Calendar.current.date(byAdding: .year, value: -13, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let document = DocumentWithIdentityAndBirthday(dateOfBirth: birthday, firstName: child2.firstName, lastName: child2.lastName)

        let validation = scheduler.createObserver(Never.self)
        _ = childrenValidator.validate(document: document)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }
}

struct DocumentWithIdentityAndBirthday: Document, ContainsDateOfBirth, AssociableToIdentity, Codable {
    var identifier: Int = 0

    var originalCode: String = ""

    var hashSeed: String = ""

    var expiresAt: Date = Date()

    var dateOfBirth: Date

    var firstName: String
    var lastName: String

    func belongsToUser(withFirstName: String, lastName: String) -> Bool {
        firstName.lowercased() == withFirstName.lowercased() && self.lastName.lowercased() == lastName.lowercased()
    }

}
