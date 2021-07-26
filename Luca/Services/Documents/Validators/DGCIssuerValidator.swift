import Foundation
import RxSwift

class DGCIssuerValidator: DocumentValidator {

    func validate(document: Document) -> Completable {
        Maybe.from { document as? DocumentWithIssuer }
            .flatMap { document -> Maybe<Never> in
                if document.issuer.removeWhitespaces().isEmpty {
                    return Maybe.error(CoronaTestProcessingError.noIssuer)
                }
                return Maybe.empty()
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}

protocol DocumentWithIssuer {
    var issuer: String { get }
}

extension DGCCoronaTest: DocumentWithIssuer {}
extension DGCVaccination: DocumentWithIssuer {}
extension DGCRecovery: DocumentWithIssuer {}
