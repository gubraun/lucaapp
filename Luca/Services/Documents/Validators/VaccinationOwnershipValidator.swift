import Foundation
import RxSwift

class VaccinationOwnershipValidator: DocumentValidator {

    private let preferences: LucaPreferences

    init(preferences: LucaPreferences) {
        self.preferences = preferences
    }

    func validate(document: Document) -> Completable {
        Maybe<Vaccination>.from { document as? Vaccination }
            .flatMap { vaccination -> Maybe<Vaccination> in
                if let firstName = self.preferences.firstName,
                   let lastName = self.preferences.lastName,
                   vaccination.belongsToUser(withFirstName: firstName, lastName: lastName) {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.validationFailed)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
