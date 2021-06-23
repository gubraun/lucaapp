import Foundation
import RxSwift

protocol DocumentValidator {

    /// Validates document. Fails if the validation chek is not fulfilled
    /// - Parameter document: Document to validate
    func validate(document: Document) -> Completable
}
