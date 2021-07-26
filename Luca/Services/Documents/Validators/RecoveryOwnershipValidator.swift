import Foundation
import RxSwift

class RecoveryOwnershipValidator: DocumentValidator {

    private let preferences: LucaPreferences

    init(preferences: LucaPreferences) {
        self.preferences = preferences
    }

    func validate(document: Document) -> Completable {
        Maybe<Recovery>.from { document as? Recovery }
            .flatMap { recovery -> Maybe<Recovery> in
                if let firstName = self.preferences.firstName,
                   let lastName = self.preferences.lastName,
                   recovery.belongsToUser(withFirstName: firstName, lastName: lastName) {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.validationFailed)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
