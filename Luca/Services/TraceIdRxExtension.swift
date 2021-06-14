import Foundation
import RxSwift

extension TraceIdService {

    /// Emits true if user is checked in, false otherwise
    func fetchTraceStatusRx() -> Single<Bool> {
        self.fetchTraceStatus().andThen(isCurrentlyCheckedIn)
    }

    /// Emits new void signals whenever user has been checked out
    func onCheckOutRx() -> Observable<TraceInfo> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onCheckOut), object: self)
            .map { $0.userInfo?["traceInfo"] }
            .map { $0 as? TraceInfo }
            .unwrapOptional()
    }

    /// Emits new void signals whenever user has been checked in
    func onCheckInRx() -> Observable<TraceInfo> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onCheckIn), object: self)
            .map { $0.userInfo?["traceInfo"] }
            .map { $0 as? TraceInfo }
            .unwrapOptional()
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
