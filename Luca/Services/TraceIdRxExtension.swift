import Foundation
import RxSwift

extension TraceIdService {

    /// Emits true if user is checked in, false otherwise
    func fetchTraceStatusRx() -> Single<Bool> {
        Single.create { (observer) -> Disposable in

            self.fetchTraceStatus { () in
                observer(.success(self.isCurrentlyCheckedIn))
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    /// Emits new void signals whenever user has been checked out
    func onCheckOutRx() -> Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onCheckOut), object: self).map { _ in Void() }
    }

    /// Emits new void signals whenever user has been checked in
    func onCheckInRx() -> Observable<TraceInfo> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onCheckIn), object: self).map { _ in self.currentTraceInfo }.unwrapOptional(errorOnNil: true).logError(self, "onCheckInRx")
    }

    func checkOutRx() -> Completable {
        Completable.create { (observer) -> Disposable in
            self.checkOut {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    var isCurrentlyCheckedInChanges: Observable<Bool> {
        let checkValue = Single.from { self.isCurrentlyCheckedIn }
        let updateSignals = Observable.merge(self.onCheckOutRx(), self.onCheckInRx().map { _ in Void() })
        return Observable.merge(checkValue.asObservable(), updateSignals.flatMap { _ in checkValue })
    }
}
