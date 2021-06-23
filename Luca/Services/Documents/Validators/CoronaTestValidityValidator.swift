import Foundation
import RxSwift

class CoronaTestValidityValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Maybe<CoronaTest>.from { document as? CoronaTest }
            .flatMap { $0.isValid().asMaybe() }
            .flatMap { isValid -> Maybe<Never> in
                if isValid {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.expired)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
