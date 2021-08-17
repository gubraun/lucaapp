import RxTest
import RxSwift
import XCTest
@testable import Luca_Debug

class AgeUnder14ValidatorTests: XCTestCase {

    var scheduler: TestScheduler!
    var validator = ChildAgeValidator()

    override func setUpWithError() throws {
        scheduler = TestScheduler(initialClock: 0)
    }

    func test_ageBelow14_success() {
        guard let birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: DocumentWithBirthday(dateOfBirth: birthday))
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

    func test_ageEquals14_success() {
        guard let birthday = Calendar.current.date(byAdding: .year, value: -14, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: DocumentWithBirthday(dateOfBirth: birthday))
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

    func test_ageAbove14_fail() {
        guard let birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date()) else {
            XCTFail("Couldn't obtain birthday")
            return
        }

        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: DocumentWithBirthday(dateOfBirth: birthday))
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.invalidChildAge)])

    }
}

struct DocumentWithBirthday: Document, ContainsDateOfBirth {
    var identifier: Int = 0

    var originalCode: String = ""

    var hashSeed: String = ""

    var expiresAt: Date = Date()

    var dateOfBirth: Date
}
