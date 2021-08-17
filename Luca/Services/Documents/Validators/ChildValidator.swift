import Foundation
import RxSwift

/// Validates if given document is identifiable with given person AND its age is below or equal 14
class ChildValidator: CompoundValidatorAnd {

    init(personSource: Single<Person>) {
        super.init(validators: [
                    ChildAgeValidator(),
                    DocumentOwnershipValidator(
                        firstNameSource: personSource.map { $0.firstName },
                        lastNameSource: personSource.map { $0.lastName }
                    )])
    }
}
