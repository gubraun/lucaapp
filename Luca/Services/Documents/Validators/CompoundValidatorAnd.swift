import RxSwift

/// A compound validator that fails if any of the given validators fails. If it fails it emits first encountered error
class CompoundValidatorAnd: DocumentValidator {

    private let validators: [DocumentValidator]
    init(validators: [DocumentValidator]) {
        self.validators = validators
    }

    func validate(document: Document) -> Completable {
        Completable.zip(validators.map { $0.validate(document: document) })
    }
}
