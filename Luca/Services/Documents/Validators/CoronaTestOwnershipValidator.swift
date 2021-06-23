import Foundation
import RxSwift

class CoronaTestOwnershipValidator: DocumentValidator {

    private let preferences: LucaPreferences

    init(preferences: LucaPreferences) {
        self.preferences = preferences
    }

    func validate(document: Document) -> Completable {
        Maybe<CoronaTest>.from { document as? CoronaTest }
            .flatMap { coronaTest -> Maybe<CoronaTest> in
                if let firstName = self.preferences.firstName,
                   let lastName = self.preferences.lastName,
                      coronaTest.belongsToUser(withFirstName: firstName, lastName: lastName) {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.validationFailed)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
