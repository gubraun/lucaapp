import Foundation
import RxSwift

public class AsyncOperation<ErrorType> where ErrorType: Error {

    @discardableResult
    func execute(completion: @escaping () -> Void, failure: @escaping (ErrorType) -> Void) -> (() -> Void) {
        fatalError("Not implemented")
    }

}

extension AsyncOperation {
    func asCompletable() -> Completable {
        Completable.create { (observer) -> Disposable in
            let execution = self.execute {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create {
                execution()
            }
        }
    }
}
