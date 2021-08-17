import RxTest
import RxSwift
import XCTest
@testable import Luca_Debug

class CompoundValidatorAndTests: XCTestCase {

    var scheduler: TestScheduler!

    override func setUpWithError() throws {
        scheduler = TestScheduler(initialClock: 0)
    }

    func test_0_from_3_validatorsSucceed_fail() {
        let validator = CompoundValidatorAnd(validators: [AlwaysFailValidator(), AlwaysFailValidator(), AlwaysFailValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.validationFailed)])
    }

    func test_1_from_3_validatorsSucceed_fail() {
        let validator = CompoundValidatorAnd(validators: [AlwaysFailValidator(), AlwaysSucceedValidator(), AlwaysFailValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.validationFailed)])
    }

    func test_2_from_3_validatorsSucceed_fail() {
        let validator = CompoundValidatorAnd(validators: [AlwaysSucceedValidator(), AlwaysSucceedValidator(), AlwaysFailValidator()])
        let validation = scheduler.createObserver(Never.self)
        _ = validator.validate(document: SimpleDocument())
            .subscribe(on: scheduler)
            .observe(on: scheduler)
            .asObservable()
            .subscribe(validation)

        scheduler.start()

        XCTAssertEqual(validation.events, [.error(2, CoronaTestProcessingError.validationFailed)])
    }

    func test_3_from_3_validatorsSucceed_success() {
        let validator = CompoundValidatorAnd(validators: [AlwaysSucceedValidator(), AlwaysSucceedValidator(), AlwaysSucceedValidator()])
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
