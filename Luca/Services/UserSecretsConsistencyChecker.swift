import Foundation
import RxSwift

class UserSecretsConsistencyChecker {

    private var disposeBag = DisposeBag()

    init(userKeysBundle: UserKeysBundle,
         traceIdService: TraceIdService,
         userService: UserService,
         lucaPreferences: LucaPreferences,
         dailyKeyHandler: DailyKeyRepoHandler) {

        // If some changes have beed registered
        // 1. Checkout current stay
        // 2. Dispose user ID
        // 3. Register user with same data
        // 4. Dispose all traces

        // 1.
        let checkOutIfNeeded = traceIdService
            .isCurrentlyCheckedIn
            .flatMapCompletable { isCheckedIn in
                if isCheckedIn {
                    return traceIdService.checkOut()
                }
                return Completable.empty()
            }
            .debug(logUtil: self, "Check secrets 0")
            .logError(self, "Checkout")
            .retry(delay: .milliseconds(500), scheduler: LucaScheduling.backgroundScheduler)

        // 2.
        _ = Completable.from { lucaPreferences.uuid = nil }

        // 3.
        _ = userService
            .registerIfNeededRx()
            .debug(logUtil: self, "Check secrets 1")
            .logError(self, "Register")
            .retry(delay: .milliseconds(500), scheduler: LucaScheduling.backgroundScheduler)
            .asObservable()
            .ignoreElementsAsCompletable()

        // 4.
        let disposeTraceData = Completable.from { traceIdService.disposeData(clearTraceHistory: true) }

        userKeysBundle.onDataPopulationRx
            .debug(logUtil: self, "Check secrets w0")
            .filter { _ in userService.isDataComplete }
            .flatMap { _ in
                checkOutIfNeeded
                    .andThen(disposeTraceData.debug(logUtil: self, "trace data disposal"))
            }
            .logError(self, "Check secrets consistency")
            .retry(delay: .milliseconds(500), scheduler: LucaScheduling.backgroundScheduler) // Just in case, this stream has to run continuously
            .debug(logUtil: self, "Check secrets whole")
            .subscribe()
            .disposed(by: disposeBag)

    }

    func disable() {
        disposeBag = DisposeBag()
    }
}

extension UserSecretsConsistencyChecker: LogUtil, UnsafeAddress {}
