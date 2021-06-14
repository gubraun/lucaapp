import Foundation
import RxSwift

extension TraceIdService {

    /// Emits true if user is checked in, false otherwise
    func fetchTraceStatusRx() -> Single<Bool> {
        self.fetchTraceStatus().andThen(isCurrentlyCheckedIn)
    }

    /// Emits new void signals whenever user has been checked out
    func onCheckOutRx() -> Observable<TraceInfo?> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onCheckOut), object: self)
            .map { $0.userInfo?["traceInfo"] }
            .map { $0 as? TraceInfo }
    }

    /// Emits new void signals whenever user has been checked in
    func onCheckInRx() -> Observable<TraceInfo> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onCheckIn), object: self)
            .flatMap { _ in

                // Force error if empty
                self.currentTraceInfo.asObservable().asSingle()
            }
            .logError(self, "onCheckInRx")
    }

    var isCurrentlyCheckedInChanges: Observable<Bool> {
        let updateSignals = Observable.merge(
            self.onCheckOutRx().map { _ in Void() },
            self.onCheckInRx().map { _ in Void() }
        )
        return Observable.merge(isCurrentlyCheckedIn.asObservable(), updateSignals.flatMap { _ in self.isCurrentlyCheckedIn })
    }
}
