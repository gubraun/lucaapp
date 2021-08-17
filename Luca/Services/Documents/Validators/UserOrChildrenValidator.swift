import Foundation
import RxSwift

/// Validates if given document belongs to user OR to one of saved children
class UserOrChildValidator: DocumentValidator {
    private let personsSource: Single<[Person]>
    private let userIdentityValidator: DocumentValidator

    init(userIdentityValidator: DocumentValidator, personsSource: Single<[Person]>) {
        self.personsSource = personsSource
        self.userIdentityValidator = userIdentityValidator
    }

    func validate(document: Document) -> Completable {
        childrenValidators()
            .map { (childrenValidators: [ChildValidator]) -> CompoundValidatorOr in
                var validators: [DocumentValidator] = childrenValidators
                validators.append(self.userIdentityValidator)
                return CompoundValidatorOr(validators: validators)
            }
            .flatMapCompletable { $0.validate(document: document) }
    }

    private func childrenValidators() -> Single<[ChildValidator]> {
        personsSource
            .asObservable()
            .flatMap { Observable.from($0) }
            .map { ChildValidator(personSource: Single.just($0)) }
            .toArray()
    }
}
