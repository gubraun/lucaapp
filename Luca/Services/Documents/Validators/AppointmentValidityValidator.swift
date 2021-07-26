import Foundation
import RxSwift

class AppointmentValidityValidator: DocumentValidator {
    func validate(document: Document) -> Completable {
        Maybe<Appointment>.from { document as? Appointment }
            .flatMap { appointment -> Maybe<Never> in
                if appointment.isValid() {
                    return Maybe.empty()
                }
                return Maybe.error(CoronaTestProcessingError.expired)
            }
            .asObservable()
            .ignoreElementsAsCompletable()
    }
}
