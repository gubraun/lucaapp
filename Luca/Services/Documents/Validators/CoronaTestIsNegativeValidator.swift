import Foundation
import RxSwift

class CoronaTestIsNegativeValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Maybe<CoronaTest>.from { document as? CoronaTest }
            .map { ($0.isNegative, $0.isValidPositive) }
            .flatMap { isNegative, isValidPositive -> Maybe<Never> in
                if isNegative || isValidPositive {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.positiveTest)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
