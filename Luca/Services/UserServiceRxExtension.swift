import Foundation
import RxSwift

extension UserService {
    var onUserUpdatedRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onUserUpdated), object: self).map { _ in Void() }
    }
    var onUserRegisteredRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onUserRegistered), object: self).map { _ in Void() }
    }
    var onUserDataTransferedRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onUserDataTransfered), object: self).map { _ in Void() }
    }

    func registerIfNeededRx() -> Single<Result> {
        Single.create { (observer) -> Disposable in
            self.registerIfNeeded { (result) in
                observer(.success(result))
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
}
