import Foundation
import RxSwift

class CoronaTestIsNegativeValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Maybe<CoronaTest>.from { document as? CoronaTest }
            .map { $0.isNegative }
            .flatMap { isValid -> Maybe<Never> in
                if isValid {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.positiveTest)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
