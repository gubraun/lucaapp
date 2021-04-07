import Foundation
import RxSwift

public class AsyncDataOperation<ErrorType, Result> where ErrorType: Error {
    
    /// - returns: cancel token. Operation will be canceled if executed
    @discardableResult
    func execute(completion: @escaping (Result) -> Void, failure: @escaping (ErrorType) -> Void) -> (()->Void) {
        fatalError("Not implemented")
    }
    
}

extension AsyncDataOperation {
    func asSingle() -> Single<Result> {
        Single<Result>.create { (observer) -> Disposable in
            let execution = self.execute { result in
                observer(.success(result))
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create {
                execution()
            }
        }
    }
}
