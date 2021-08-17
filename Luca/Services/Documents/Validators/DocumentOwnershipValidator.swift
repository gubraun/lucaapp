import Foundation
import RxSwift

/// Validates if given first and last name match those in the given document. If not it emits `CoronaTestProcessingError.nameValidationFailed`
class DocumentOwnershipValidator: DocumentValidator {

    private let firstNameSource: Single<String>
    private let lastNameSource: Single<String>

    init(firstNameSource: Single<String>, lastNameSource: Single<String>) {
        self.firstNameSource = firstNameSource
        self.lastNameSource = lastNameSource
    }

    func validate(document: Document) -> Completable {
        Maybe<AssociableToIdentity>.from { document as? AssociableToIdentity }
            .flatMap { identifiable -> Maybe<(AssociableToIdentity, String, String)> in
                Single.zip(self.firstNameSource, self.lastNameSource)
                    .map { (identifiable, $0, $1) }
                    .asMaybe()
            }
            .flatMap { (identifiable: AssociableToIdentity, firstName: String, lastName: String) -> Maybe<AssociableToIdentity> in
                if identifiable.belongsToUser(withFirstName: firstName, lastName: lastName) {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.nameValidationFailed)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
