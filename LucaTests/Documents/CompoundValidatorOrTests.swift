import RxTest
import RxSwift
import XCTest
@testable import Luca_Debug

class CompoundValidatorOrTests: XCTestCase {

    var scheduler: TestScheduler!

    override func setUpWithError() throws {
        scheduler = TestScheduler(initialClock: 0)
    }

    func test_0_from_3_validatorsSucceed_fail() {
        let validator = CompoundValidatorOr(validators: [AlwaysFailValidator(), AlwaysFailValidator(), AlwaysFailValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.validationFailed)])
    }

    func test_1_from_3_validatorsSucceed_success() {
        let validator = CompoundValidatorOr(validators: [AlwaysSucceedValidator(), AlwaysFailValidator(), AlwaysFailValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

    func test_2_from_3_validatorsSucceed_success() {
        let validator = CompoundValidatorOr(validators: [AlwaysSucceedValidator(), AlwaysSucceedValidator(), AlwaysFailValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

    func test_3_from_3_validatorsSucceed_success() {
        let validator = CompoundValidatorOr(validators: [AlwaysSucceedValidator(), AlwaysSucceedValidator(), AlwaysSucceedValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.completed(2)])
    }

}

class AlwaysFailValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Completable.error(CoronaTestProcessingError.validationFailed)
    }
}

class AlwaysSucceedValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Completable.empty()
    }
}
