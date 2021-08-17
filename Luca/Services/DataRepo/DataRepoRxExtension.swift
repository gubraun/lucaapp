import Foundation
import RxSwift

extension DataRepoProtocol {

    func store(object: Model) -> Single<Model> {
        Single<Model>.create { (observer) -> Disposable in
            self.store(object: object) { (stored) in
                observer(.success(stored))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }

    func store(objects: [Model]) -> Single<[Model]> {
        Single<[Model]>.create { (observer) -> Disposable in
            self.store(objects: objects) { (stored) in
                observer(.success(stored))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }

    func restore() -> Single<[Model]> {
        Single<[Model]>.create { (observer) -> Disposable in
            self.restore { (restored) in
                observer(.success(restored))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }

    func remove(identifiers: [Int]) -> Completable {
        Completable.create { (observer) -> Disposable in
            self.remove(identifiers: identifiers) {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    func removeAll() -> Completable {
        Completable.create { (observer) -> Disposable in
            self.removeAll {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
}

extension DataRepoProtocol where Self: AnyObject {
    var onDataChanged: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onDataChanged), object: self).map { _ in Void() }
    }
}
