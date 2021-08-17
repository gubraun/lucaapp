import Foundation
import RxSwift

protocol ContainsDateOfBirth {
    var dateOfBirth: Date { get }
}

/// Validates if given document contains a date of birth and it's equal or below 14, if not it emits `CoronaTestProcessingError.invalidChildAge`
class ChildAgeValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Maybe<ContainsDateOfBirth>.from { document as? ContainsDateOfBirth }
            .flatMap { document -> Maybe<Never> in
                if let age = Calendar.current.dateComponents([.year], from: document.dateOfBirth, to: Date()).year,
                   age > 14 {
                    throw CoronaTestProcessingError.invalidChildAge
                }
                return Maybe.empty()
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
