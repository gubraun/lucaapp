import RxSwift

/// A compound validator that succeeds if any of the given validators succeeds. If it fails it emits first encountered error
class CompoundValidatorOr: DocumentValidator {

    private let validators: [DocumentValidator]
    init(validators: [DocumentValidator]) {
        self.validators = validators
    }

    func validate(document: Document) -> Completable {

        let observables: [Observable<Event<Void>>] = validators
            .map { $0.validate(document: document) }
            .map { $0.andThen(Single.just(Void())) }
            .map { $0.asObservable() }
            .map { $0.materialize() }

        return Observable.merge(observables)
            .toArray()
            .flatMapCompletable { events in
                if events.contains(where: { $0.element != nil }) {
                    return Completable.empty()
                } else if let firstError = events.first(where: { $0.error != nil }),
                          let error = firstError.error {
                    throw error
                }

                // It was empty?
                return Completable.empty()
            }
    }
}
