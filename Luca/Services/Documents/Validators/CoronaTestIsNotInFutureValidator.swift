import Foundation
import RxSwift

class CoronaTestIsNotInFutureValidator: DocumentValidator {

    func validate(document: Document) -> Completable {
        Maybe<CoronaTest>.from { document as? CoronaTest }
            .map { $0.date }
            .flatMap { date -> Maybe<Never> in
                if date < Date() {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.testInFuture)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }

}
