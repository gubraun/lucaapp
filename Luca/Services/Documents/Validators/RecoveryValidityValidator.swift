import Foundation
import RxSwift

class RecoveryValidityValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Maybe<Recovery>.from { document as? Recovery }
            .flatMap { recovery -> Maybe<Never> in
                if recovery.isValid() {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.expired)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
