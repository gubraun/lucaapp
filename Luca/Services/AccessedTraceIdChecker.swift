import Foundation
import RxSwift
import BackgroundTasks

struct AccessedTraceId: Equatable {
    var healthDepartmentId: Int
    var traceInfoIds: [Int]

    /// Date when this data set has been sighted
    var sightDate: Date

    /// Date when this dataset has been notified to user per local notification
    var localNotificationDate: Date?

    /// Date when this dataset has been actually seen by the user
    var consumptionDate: Date?
}

extension AccessedTraceId {
    var hasBeenSeenByUser: Bool {
        consumptionDate != nil && Date().timeIntervalSince1970 > consumptionDate!.timeIntervalSince1970
    }

    var hasBeenNotified: Bool {
        localNotificationDate != nil && Date().timeIntervalSince1970 > localNotificationDate!.timeIntervalSince1970
    }
}

class AccessedTraceIdChecker {

    private let backend: BackendMiscV3
    private let traceInfoRepo: TraceInfoRepo
    private let accessedTraceIdRepo: AccessedTraceIdRepo
    private let healthDepartmentRepo: HealthDepartmentRepo

    private let _accessedTraceIds = BehaviorSubject(value: [AccessedTraceId]())

    private var notificationDisposeBag: DisposeBag?

    /// Emits current and updated accessedTraceIds; No filtering at all
    var accessedTraceIds: Observable<[AccessedTraceId]> {
        _accessedTraceIds
        .distinctUntilChanged()
    }

    var currentAccessedTraceIds: [AccessedTraceId] {
        (try? _accessedTraceIds.value()) ?? []
    }

    init(
        backend: BackendMiscV3,
        traceInfoRepo: TraceInfoRepo,
        healthDepartmentRepo: HealthDepartmentRepo,
        accessedTraceIdRepo: AccessedTraceIdRepo) {
        self.backend = backend
        self.traceInfoRepo = traceInfoRepo
        self.accessedTraceIdRepo = accessedTraceIdRepo
        self.healthDepartmentRepo = healthDepartmentRepo
    }

    func fetchAccessedTraceIds() -> Completable {
        retrievePastTraceInfos()
            .asObservable()
            .flatMap { infos -> Completable in
                // Pull only if there exist local traces to compare to
                if !infos.isEmpty {
                    return self.backend.fetchAccessedTraces()
                        .asSingle()
                        .asObservable()
                        .observe(on: LucaScheduling.backgroundScheduler)
                        .flatMap { self.storeHealthDepartments(accessedTraces: $0).andThen(Observable.just($0)) }
                        .flatMap { self.prepareAccessedTraces(accessedTraces: $0) }
                        .ignoreElementsAsCompletable()
                        .onErrorComplete()
                }
                return Completable.empty()
            }
            .asCompletable()
    }

    func consume(accessedTraces: [AccessedTraceId]) -> Completable {
        if accessedTraces.isEmpty {
            return Completable.empty()
        }
        return Single.from { accessedTraces }
            .map { $0.map { (accessedTrace: AccessedTraceId) in
                var copy = accessedTrace
                copy.consumptionDate = Date()
                return copy
            }}
            .flatMap { self.accessedTraceIdRepo.store(objects: $0) }
            .flatMap { _ in self.accessedTraceIdRepo.restore() }
            .do(onSuccess: { self._accessedTraceIds.onNext($0) })
            .asCompletable()
    }

    private func generateHashedTraceInfoDictionary(_ traceInfos: [TraceInfo], with healthDepartmentId: UUID) -> [String: TraceInfo] {
        let hdID = Data(healthDepartmentId.bytes)
        let hmac = HMACSHA256(key: hdID)
        let retVal = traceInfos.reduce([String: TraceInfo]()) { (dict, traceInfo: TraceInfo) in
            var d = dict

            if let traceIdData = traceInfo.traceIdData {
                let hashed = (try? hmac.encrypt(data: traceIdData.data)) ?? Data()
                d[hashed.prefix(16).base64EncodedString()] = traceInfo
            }
            return d
        }
        return retVal
    }

    private func storeHealthDepartments(accessedTraces: [AccessedTrace]) -> Completable {
        healthDepartmentRepo.store(objects: accessedTraces.map { $0.healthDepartment })
            .asObservable()
            .ignoreElementsAsCompletable()
    }

    private func storeAccessedTraceIds(ids: [AccessedTraceId]) -> Single<[AccessedTraceId]> {
        accessedTraceIdRepo.store(objects: ids)
    }

    private func prepareAccessedTraces(accessedTraces: [AccessedTrace]) -> Completable {
        Observable.combineLatest(retrievePastTraceInfos().asObservable(), retrieveAccessedTraceInfos().asObservable())
            .take(1)
            .asSingle()
            .map { (traceInfos: [TraceInfo], accessedTraceInfos: [AccessedTraceId]) -> [AccessedTraceId] in
                return accessedTraces
                    .map { (accessedTraceId: AccessedTrace) in

                        let hdID = UUID(uuidString: accessedTraceId.healthDepartment.departmentId) ?? UUID()

                        let hashedTraceIds = self.generateHashedTraceInfoDictionary(traceInfos, with: hdID)

                        // Contains the intersection between users trace ids and fetched trace ids
                        let intersection = accessedTraceId.intersection(with: hashedTraceIds)

                        return AccessedTraceId(
                            healthDepartmentId: accessedTraceId.healthDepartment.identifier ?? -1,
                            traceInfoIds: intersection.map { $0.identifier ?? -1 },
                            sightDate: Date())
                    }
                    .filter { !$0.traceInfoIds.isEmpty }

                    // Filter out those, which are already in the database to not overwrite informations about usage like sightDate etc.
                    .filter { (generatedAccessedTraceId: AccessedTraceId) in
                        !accessedTraceInfos.contains(where: { $0.identifier == generatedAccessedTraceId.identifier })
                    }
            }
            .flatMap { self.storeAccessedTraceIds(ids: $0) }
            .flatMap { _ in self.accessedTraceIdRepo.restore() }
            .do(onSuccess: { self._accessedTraceIds.onNext($0) })
            .asObservable()
            .ignoreElementsAsCompletable()
    }

    private func retrievePastTraceInfos() -> Single<[TraceInfo]> {
        self.traceInfoRepo
            .restore()
            .map { array in array.filter { $0.traceIdData != nil } }
    }
    private func retrieveAccessedTraceInfos() -> Single<[AccessedTraceId]> {
        self.accessedTraceIdRepo
            .restore()
    }

    var newNotificationDisposeBag = DisposeBag()
    @available(iOS 13.0, *)
    func sendNotificationOnMatch(task: BGAppRefreshTask) {
        performFetchForNotification()
            .do(onSuccess: { _ in
                task.setTaskCompleted(success: true)
            }, onError: { _ in
                task.setTaskCompleted(success: false)
            })
            .subscribe()
            .disposed(by: newNotificationDisposeBag)
        notificationDisposeBag = newNotificationDisposeBag
    }

    func sendNotificationOnMatch(completionHandler: @escaping(UIBackgroundFetchResult) -> Void) {
        performFetchForNotification()
            .do(onSuccess: { _ in
                completionHandler(.newData)
            }, onError: { _ in
                completionHandler(.noData)
            })
            .subscribe()
            .disposed(by: newNotificationDisposeBag)
        notificationDisposeBag = newNotificationDisposeBag
    }

    private func performFetchForNotification() -> Single<[AccessedTraceId]> {
        fetchAccessedTraceIds()
            .andThen(accessedTraceIds)
            .take(1)
            .map { array in array.filter({ !$0.hasBeenNotified && !$0.hasBeenSeenByUser}) }
            .do(onNext: { readElements in
                if !readElements.isEmpty {
                    DispatchQueue.main.async { NotificationScheduler.shared.scheduleNotification(title: L10n.Data.Access.title, message: L10n.Data.Access.Notification.description) }
                }
            })
            .asSingle()
            .flatMap { notifiedElements in
                self.setAsNotified(accessedTraces: notifiedElements).andThen(Single.just(notifiedElements))
            }
    }

    private func setAsNotified(accessedTraces: [AccessedTraceId]) -> Completable {
        if accessedTraces.isEmpty {
            return Completable.empty()
        }
        return Single.from { accessedTraces }
            .map { $0.map { (accessedTrace: AccessedTraceId) in
                var copy = accessedTrace
                copy.localNotificationDate = Date()
                return copy
            }}
            .flatMap { self.accessedTraceIdRepo.store(objects: $0) }
            .flatMap { _ in self.accessedTraceIdRepo.restore() }
            .do(onSuccess: { self._accessedTraceIds.onNext($0) })
            .asCompletable()
    }

    func disposeNotificationOnMatch() {
        notificationDisposeBag = nil
    }

}

extension AccessedTraceIdChecker: LogUtil, UnsafeAddress {}

class AccessedTraceIdPairer {

    private static let logUtil = GeneralPurposeLog(subsystem: "App", category: "AccessedTraceIdPairer", subDomains: [])

    static func pairAccessedTraceProperties(accessedTraceId: AccessedTraceId) -> Single<[HealthDepartment: [(TraceInfo, Location)]]> {
        return pairTraceInfos(accessedTraceId: accessedTraceId).flatMap {
            pairLocation(infos: $0)
        }
    }

    static func pairTraceInfos(accessedTraceId: AccessedTraceId) -> Single<(HealthDepartment, [TraceInfo])> {
        ServiceContainer.shared.traceInfoRepo
            .restore()
            .flatMap { traceInfos in
                self.pairHealthDepartment(departmentId: accessedTraceId.healthDepartmentId)
                    .map { ($0, accessedTraceId.traceInfoIds) }
                    .map { (department, traceInfoIds) -> (HealthDepartment, [TraceInfo]) in
                        let ids = traceInfoIds.map { id in
                            traceInfos.first(where: { $0.identifier == id })
                        }.unwrapOptional()
                    return (department, ids)
                }
            }
    }

    static func pairHealthDepartment(departmentId: Int) -> Single<HealthDepartment> {
        ServiceContainer.shared.healthDepartmentRepo
            .restore()
            .map { departments in
                departments.first(where: { $0.identifier == departmentId })
            }
            .filter { $0 != nil }
            .asObservable()
            .asSingle()
            .map { $0! }
            .debug("Pair health department")
            .logError(logUtil, "Health department id could not be matched")
    }

    static func pairLocation(infos: (HealthDepartment, [TraceInfo])) -> Single<[HealthDepartment: [(TraceInfo, Location)]]> {
        ServiceContainer.shared.locationRepo
            .restore()
            .map { locations in
                let traces = infos.1.map { traceInfo in
                    (traceInfo, locations.first(where: { $0.locationId == traceInfo.locationId }))
                }
                .filter { $0.1 != nil }
                .map { ($0.0, $0.1!) }
                return [infos.0: traces]
            }
    }

}
