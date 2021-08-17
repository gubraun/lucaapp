import RxTest
import RxSwift
import XCTest
@testable import Luca_Debug

class DocumentOwnershipValidatorTests: XCTestCase {

    var scheduler: TestScheduler!
    var validator: DocumentOwnershipValidator!
    private let documentWithoutIdentification = SimpleDocument()
    private let documentWithEqualNames = IdentifiableDocument(firstName: "Hans", lastName: "Zimmermann")
    private let documentWithNonEqualNames = IdentifiableDocument(firstName: "Jan", lastName: "Kowalski")

    override func setUpWithError() throws {
        validator = DocumentOwnershipValidator(firstNameSource: Single.just("Hans"), lastNameSource: Single.just("Zimmermann"))
        scheduler = TestScheduler(initialClock: 0)
    }

    func test_documentWithoutIdentity_success() {
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: documentWithoutIdentification)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

    func test_documentWithFalseIdentity_fail() {
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: documentWithNonEqualNames)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.nameValidationFailed)])
    }

    func test_documentWithRightIdentity_success() {
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: documentWithEqualNames)
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }
}

struct SimpleDocument: Document {
    var identifier: Int = 0

    var originalCode: String = ""

    var hashSeed: String = ""

    var expiresAt: Date = Date()
}

struct IdentifiableDocument: Document, AssociableToIdentity {
    var identifier: Int = 0

    var originalCode: String = ""

    var hashSeed: String = ""

    var expiresAt: Date = Date()

    private let firstName: String
    private let lastName: String

    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }

    func belongsToUser(withFirstName: String, lastName: String) -> Bool {
        firstName.lowercased() == withFirstName.lowercased() && self.lastName.lowercased() == lastName.lowercased()
    }
}
