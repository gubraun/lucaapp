import Foundation
import RxSwift

extension KeyValueRepoProtocol {

    func store<T>(_ key: String, value: T) -> Completable where T: Encodable {
        Completable.create { (observer) -> Disposable in

            self.store(key, value: value) {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
    func load<T>(_ key: String, type: T.Type) -> Single<T> where T: Decodable {
        Single.create { (observer) -> Disposable in

            self.load(key, type: type) { (value) in
                observer(.success(value))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }
    func remove(_ key: String) -> Completable {
        Completable.create { (observer) -> Disposable in

            self.remove(key) {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
    func removeAll() -> Completable {
        Completable.create { (observer) -> Disposable in

            self.removeAll() {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
}
