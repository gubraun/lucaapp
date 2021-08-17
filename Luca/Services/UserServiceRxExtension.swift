import Foundation
import RxSwift

extension UserService {
    var onUserUpdatedRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onUserUpdated), object: self).map { _ in Void() }
    }
    var onUserRegisteredRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onUserRegistered), object: self).map { _ in Void() }
    }
    var onUserDataTransferedRx: Observable<Int> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onUserDataTransfered), object: self).map { notif in
            notif.userInfo?[self.onUserDataTransferedNumberOfDays] as? Int ?? 14
        }
    }

    func registerIfNeededRx() -> Single<Result> {
        Single.create { (observer) -> Disposable in
            self.registerIfNeeded { (result) in
                observer(.success(result))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }

    func update(data: UserRegistrationData) -> Completable {
        Completable.create { observer in

            self.update(data: data, completion: {
                observer(.completed)
            }) { observer(.error($0)) }

            return Disposables.create()
        }
    }

    func deleteUserData() -> Completable {
        Completable.create { observer in

            self.deleteUserData {
                observer(.completed)
            } failure: { observer(.error($0)) }

            return Disposables.create()
        }
    }
}
