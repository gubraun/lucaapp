import Foundation
import RxSwift
import RxBlocking

// swiftlint:disable file_length
enum TraceIdServiceError: LocalizedError {
    case userCheckedInAlready
    case privateMeetingRunning
    case notCheckedIn
    case unableToRetrieveLocationID
    case unableToRetrieveUserID
    case unableToCheckOut
    case unableToCheckInToOutdatedEvent
    case unableToBuildTraceId
    case locationNotFound
    case networkError(error: NetworkError)

    case unknown
}

extension TraceIdServiceError {
    var errorDescription: String? {
        switch self {
        case .userCheckedInAlready:
            return L10n.Checkin.Failure.AlreadyCheckedIn.message
        case .privateMeetingRunning:
            return L10n.Checkin.Failure.PrivateMeetingRunning.message
        case .unableToCheckInToOutdatedEvent:
            return L10n.Checkin.Failure.NotAvailableAnymore.message
        case .networkError(let error):
            return error.errorDescription
        default:
            return "\(self)"
        }
    }
}

// swiftlint:disable:next type_body_length
class TraceIdService {
    private let qrCodeGenerator: QRCodePayloadBuilderV3
    private let lucaPreferences: LucaPreferences
    private let dailyKeyRepo: DailyPubKeyHistoryRepository
    private let ePubKeyRepo: EphemeralPublicKeyHistoryRepository
    private let ePrivKeyRepo: EphemeralPrivateKeyHistoryRepository
    private let preferences: Preferences
    private let backend: BackendTraceIdV3
    private let backendMisc: CommonBackendMisc
    private let backendLocation: BackendLocationV3
    private let privateMeetingService: PrivateMeetingService
    private let traceInfoRepo: TraceInfoRepo
    private let locationRepo: LocationRepo
    private let traceIdCoreRepo: TraceIdCoreRepo

    // MARK: - event names
    public let onCheckIn: String = "TraceIdService.onCheckIn"
    public let onCheckOut: String = "TraceIdService.onCheckOut"

    // MARK: - Persisted properties
    private var oldCurrentTraces: [TraceIdCore] {
        get {
            let now = Date()
            return (preferences.retrieve(key: "currentTraces", type: [TraceIdCore].self) ?? [])
                .filter { now.timeIntervalSince1970 - $0.date.timeIntervalSince1970 < 3600.0 } // Only traceIds from the last hour
        }
        set {
            preferences.store(newValue, key: "currentTraces")
        }
    }

    private var oldTraceInfos: [TraceInfo] {
        get {
            preferences.retrieve(key: "traceInfos", type: [TraceInfo].self) ?? []
        }
        set {
            preferences.store(newValue, key: "traceInfos")
        }
    }

    var additionalData: Codable? {
        if let value = preferences.retrieve(key: "additionalData", type: TraceIdAdditionalData.self) { return value }
        if let value = preferences.retrieve(key: "additionalData", type: PrivateMeetingQRCodeV3AdditionalData.self) { return value }
        // This should be always checked as last value as it is at least restrictive and wins with other structs that have this data format
        if let value = preferences.retrieve(key: "additionalData", type: [String: String].self) { return value }
        return nil
    }
    private func store<T>(additionalData: T) where T: Codable {
        preferences.store(additionalData, key: "additionalData")
    }
    private func removeAdditionalData() {
        preferences.remove(key: "additionalData")
    }

    // MARK: - helper properties

    /// This indicates if the consistency check has been already run in current runtime
    private var consistencyCheckAlreadyRun = false

    var currentTraceInfo: Maybe<TraceInfo> {
        checkCorrectnessOfLocalTraceInfoData()
            .andThen(traceInfoRepo.restore())
            .asObservable()
            .flatMap { array in Maybe.from { array.filter { $0.isCheckedIn }.sorted(by: { $0.checkin > $1.checkin }).first } }
            .asMaybe()
    }

    var checkedInTraceId: Maybe<TraceId> {
        return currentTraceInfo.map { $0.traceIdData }.unwrapOptional()
    }

    /// It returns current known status without checking with backend
    var isCurrentlyCheckedIn: Single<Bool> {
        return checkedInTraceId.asObservable().count { _ in true }.map { $0 > 0 }
    }

    private var cachedTraceIds: [TraceIdCore: TraceId] = [:]

    // MARK: - public implementation
    init(qrCodeGenerator: QRCodePayloadBuilderV3,
         lucaPreferences: LucaPreferences,
         dailyKeyRepo: DailyPubKeyHistoryRepository,
         ePubKeyRepo: EphemeralPublicKeyHistoryRepository,
         ePrivKeyRepo: EphemeralPrivateKeyHistoryRepository,
         preferences: Preferences,
         backendTrace: BackendTraceIdV3,
         backendMisc: CommonBackendMisc,
         backendLocation: BackendLocationV3,
         privateMeetingService: PrivateMeetingService,
         traceInfoRepo: TraceInfoRepo,
         locationRepo: LocationRepo,
         traceIdCoreRepo: TraceIdCoreRepo) {

        self.qrCodeGenerator = qrCodeGenerator
        self.lucaPreferences = lucaPreferences
        self.dailyKeyRepo = dailyKeyRepo
        self.ePubKeyRepo = ePubKeyRepo
        self.ePrivKeyRepo = ePrivKeyRepo
        self.preferences = preferences
        self.backend = backendTrace
        self.backendMisc = backendMisc
        self.backendLocation = backendLocation
        self.privateMeetingService = privateMeetingService
        self.traceInfoRepo = traceInfoRepo
        self.locationRepo = locationRepo
        self.traceIdCoreRepo = traceIdCoreRepo

        migrateOldData()
        _ = checkCorrectnessOfLocalTraceInfoData().andThen(fetchTraceStatus()).subscribe()
    }

    private func migrateOldData() {
        let loadedCurrentTraces = oldCurrentTraces
        let loadedCurrentTraceInfos = oldTraceInfos

        if !loadedCurrentTraces.isEmpty {
            do {
                _ = try self.traceIdCoreRepo.store(objects: loadedCurrentTraces)
                    .logError(self, "Migrating current trace id cores")
                    .do(onSuccess: { _ in
                        self.oldCurrentTraces = []
                    })
                    .toBlocking() // It should block
                    .toArray()
            } catch let error {
                self.log("Error migrating current trace id cores: \(error)", entryType: .error)
            }
        }

        if !loadedCurrentTraceInfos.isEmpty {
            do {
            _ = try self.traceInfoRepo.store(objects: loadedCurrentTraceInfos)
                .logError(self, "Migrating current trace infos")
                .do(onSuccess: { _ in
                    self.oldTraceInfos = []
                })
                .toBlocking() // It should block
                .toArray()
            } catch let error {
                self.log("Error migrating current trace id infos: \(error)", entryType: .error)
            }
        }
    }

    public func getOrCreateQRCode() -> Single<QRCodePayloadV3> {
        self.traceIdCoreRepo.restore()
            .map { currentTraces in currentTraces.filter { Date().timeIntervalSince1970 - $0.date.timeIntervalSince1970 < 60.0 } }
            .map { $0.first }
            .flatMap { first in
                if let first = first {
                    return Single.from { first }
                }
                return self.generateNewTraceIdCore()
            }
            .flatMap { self.buildQRCode(core: $0) }
    }

    /// Fetches current status and updates internals. It does not fetch location data, it should be fetched explicit.
    public func fetchTraceStatus() -> Completable {
        currentTraceInfo
            .asObservable()
            .map { $0.traceIdData }
            .unwrapOptional()
            .ifEmpty(switchTo: self.checkStatusWhenNotCheckedIn().andThen(Observable<TraceId>.empty()))
            .flatMap { self.checkStatusWhenCheckedIn(currentTraceId: $0) }
            .ignoreElementsAsCompletable()
    }

    /// Fetches and saves the informations from the internet. If no internet, it tries to load previously location
    public func fetchCurrentLocationInfo(checkLocalDBFirst: Bool = false) -> Single<Location> {
        let locationSource: Single<Location>
        if checkLocalDBFirst {
            locationSource = loadCurrentLocationInfo().catch { _ in self.downloadCurrentLocationInfo() }
        } else {
            locationSource = downloadCurrentLocationInfo().catch { _ in self.loadCurrentLocationInfo() }
        }

        return locationSource
    }

    /// Loads location info if retrieved and if user is currently checked in.
    public func loadCurrentLocationInfo() -> Single<Location> {
        currentTraceInfo
            .map { $0.parsedLocationId }
            .unwrapOptional()
            .ifEmpty(switchTo: Single<UUID>.error(TraceIdServiceError.notCheckedIn))
            .flatMap { locationId in
                self.locationInfo(for: locationId)
            }
    }

    /// Downloads location info if user is currently checked in.
    public func downloadCurrentLocationInfo() -> Single<Location> {
        currentTraceInfo
            .map { $0.parsedLocationId }
            .unwrapOptional()
            .ifEmpty(switchTo: Single<UUID>.error(TraceIdServiceError.notCheckedIn))
            .flatMap { locationId in
                self.backendLocation.fetchLocation(locationId: locationId).asSingle()
            }
            .map { location in
                if let privateMeeting = self.additionalData as? PrivateMeetingQRCodeV3AdditionalData {
                    var locationInfo = location
                    locationInfo.groupName = "\(privateMeeting.fn) \(privateMeeting.ln)"
                    return locationInfo
                }
                return location
            }
            .flatMap { self.locationRepo.store(object: $0) }
    }

    private func locationInfo(for locationId: UUID) -> Single<Location> {
        locationRepo.restore()
            .map { array in array.first(where: { $0.locationId.lowercased() == locationId.uuidString.lowercased() }) }
            .unwrapOptional()
    }

    // completion: @escaping () -> Void, failure: @escaping (TraceIdServiceError) -> Void
    public func checkOut() -> Completable {
        checkedInTraceId
            .ifEmpty(switchTo: Single<TraceId>.error(TraceIdServiceError.notCheckedIn))
            .asObservable()
            .asSingle()
            .flatMapCompletable {
                self.backend
                    .checkOut(traceId: $0, timestamp: Date())
                    .asCompletable()
                    .catch { error in
                        guard let interpretedError = error as? BackendError<CheckOutError> else {
                            throw error
                        }
                        if let backendError = interpretedError.backendError,
                           case .notFound = backendError {
                            return Completable.empty()
                        }
                        throw error
                    }
                    .andThen(self.checkStatusWhenCheckedIn(currentTraceId: $0))
            }
    }

    public func checkIn(selfCheckin: SelfCheckin) -> Completable {
        let checkInLogic = self.fetchScanner(for: selfCheckin)

            // Wrap internal error to another one.
            // If scanner is not available and this error is not faulted by system or connectivity,
            // its a signal that the event is outdated
            .do(onError: { error in
                if let backendError = error as? BackendError<FetchScannerError>,
                   backendError.backendError != nil {
                    throw TraceIdServiceError.unableToCheckInToOutdatedEvent
                }
            })

            .flatMapCompletable { (scannerInfo: ScannerInfo) in
                self.getOrCreateQRCode()
                    .flatMapCompletable { qrCode -> Completable in
                        guard let keyData = Data(base64Encoded: scannerInfo.publicKey) else {
                            throw NSError(domain: "Couldn't obtain key data", code: 0, userInfo: nil)
                        }
                        guard let key = KeyFactory.create(from: keyData, type: .ecsecPrimeRandom, keyClass: .public) else {
                            throw NSError(domain: "Couldn't create key from key data", code: 0, userInfo: nil)
                        }
                        let checkin = self.backend.checkIn(
                            qrCode: qrCode,
                            venuePubKey: ValueKeySource(key: key),
                            scannerId: scannerInfo.scannerId)
                        .asCompletable()

                        if let traceId = qrCode.parsedTraceId {
                            return checkin.andThen(
                                self.updateAdditionalData(for: selfCheckin, traceId: traceId, venuePubKey: key)
                            )
                        } else {
                            return checkin
                        }
                    }
            }
            .asObservable()
            .ignoreElementsAsCompletable()

        return isCurrentlyCheckedIn
            .flatMapCompletable { isCheckedIn in
                if isCheckedIn {
                    throw TraceIdServiceError.userCheckedInAlready
                }
                if self.privateMeetingService.currentMeeting != nil {
                    throw TraceIdServiceError.privateMeetingRunning
                }
                return checkInLogic
            }
            .logError(self, "check in")
    }

    private func fetchScanner(for checkin: SelfCheckin) -> Single<ScannerInfo> {
        if let privateMeeting = checkin as? PrivateMeetingSelfCheckin {
            return backendMisc.fetchScanner(scannerId: privateMeeting.scannerId).asSingle()
        } else if let tableCheckin = checkin as? TableSelfCheckin {
            return backendMisc.fetchScanner(scannerId: tableCheckin.scannerId).asSingle()
        } else {
            return Single<ScannerInfo>.error(NSError(domain: "Unsupported self checkin data", code: 0, userInfo: nil))
        }
    }

    private func updateAdditionalData(for checkin: SelfCheckin, traceId: TraceId, venuePubKey: SecKey) -> Completable {
        if let privateMeeting = checkin as? PrivateMeetingSelfCheckin {

            let firstName = self.lucaPreferences.firstName ?? "..."
            let lastName = self.lucaPreferences.lastName ?? "..."
            let usersAdditionalData = PrivateMeetingQRCodeV3AdditionalData(fn: firstName, ln: lastName)

            return backend.updateAdditionalData(
                traceId: traceId,
                scannerId: privateMeeting.scannerId,
                venuePubKey: ValueKeySource(key: venuePubKey),
                additionalData: usersAdditionalData)
                .asCompletable()
                .andThen(Completable.from { self.store(additionalData: privateMeeting.additionalData) })

        } else if let tableCheckin = checkin as? TableSelfCheckin {

            if let table = tableCheckin.additionalData {

                return backend.updateAdditionalData(
                    traceId: traceId,
                    scannerId: tableCheckin.scannerId,
                    venuePubKey: ValueKeySource(key: venuePubKey),
                    additionalData: table)
                    .asCompletable()
                    .andThen(Completable.from { self.store(additionalData: table) })

            } else if let keyValuePairs = tableCheckin.keyValues {

                return backend.updateAdditionalData(
                    traceId: traceId,
                    scannerId: tableCheckin.scannerId,
                    venuePubKey: ValueKeySource(key: venuePubKey),
                    additionalData: keyValuePairs)
                    .asCompletable()
                    .andThen(Completable.from { self.store(additionalData: keyValuePairs) })
            } else {
                return Completable.empty() // No additional data
            }
        } else {
            return Completable.error(NSError(domain: "Unsupported self checkin data", code: 0, userInfo: nil))
        }
    }

    /// Should be used to dispose data when user is not longer available or data are corrupted
    public func disposeData(clearTraceHistory: Bool) {
        if clearTraceHistory {
            _ = self.traceInfoRepo
                .removeAll()
                .debug("TraceInfo removal")
                .logError(self, "TraceInfo removal")
                .subscribe()
        }
        _ = self.traceIdCoreRepo.removeAll().logError(self, "TraceIdCores removal").subscribe()
        self.removeAdditionalData()
        self.ePubKeyRepo.removeAll()
        self.ePrivKeyRepo.removeAll()
    }

    func getOrCreateTraceId(core: TraceIdCore) throws -> TraceId {
        guard let uuid = lucaPreferences.uuid else {
            throw TraceIdServiceError.unableToRetrieveUserID
        }
        if let cached = cachedTraceIds[core] {
            return cached
        }
        let traceId = try qrCodeGenerator.traceId(core: core, userID: uuid)
        cachedTraceIds[core] = traceId
        return traceId
    }

    // MARK: - private helper
    private func generateNewTraceIdCore() -> Single<TraceIdCore> {
        Single.from { try self.retrieveNewestKeyId() }
            .map { TraceIdCore(date: Date(), keyId: UInt8($0.keyId)) }
            .do(onSuccess: { traceIdCore in

                let keyIndex = Int(traceIdCore.date.lucaTimestampInteger)
                let privKeyPresent = (try? self.ePrivKeyRepo.restore(index: keyIndex)) != nil
                let pubKeyPresent = (try? self.ePubKeyRepo.restore(index: keyIndex)) != nil
                if !privKeyPresent || !pubKeyPresent {
                    guard let privKey = KeyFactory.createPrivate(tag: "PrivKey", type: .ecsecPrimeRandom, sizeInBits: 256) else {
                        throw NSError(domain: "Couldn't generate ephemeral private key", code: 0, userInfo: nil)
                    }
                    guard let pubKey = KeyFactory.derivePublic(from: privKey) else {
                        throw NSError(domain: "Couldn't derive public key", code: 0, userInfo: nil)
                    }
                    try self.ePrivKeyRepo.store(key: privKey, index: keyIndex)
                    try self.ePubKeyRepo.store(key: pubKey, index: keyIndex)
                }
            })
            .flatMap { self.traceIdCoreRepo.store(object: $0) }
    }

    private func buildQRCode(core: TraceIdCore) -> Single<QRCodePayloadV3> {
        Single.from {
            let userId = try self.retrieveUserId()
            let code = try self.qrCodeGenerator.build(for: core, userID: userId)
            return code
        }
    }

    private func retrieveUserId() throws -> UUID {
        guard let userId = lucaPreferences.uuid else {
            throw NSError(domain: "Couldn't retrieve user id", code: 0, userInfo: nil)
        }
        return userId
    }

    private func retrieveNewestKeyId() throws -> DailyKeyIndex {
        guard let newestId = dailyKeyRepo.newestId else {
            throw NSError(domain: "No daily pub key", code: 0, userInfo: nil)
        }
        return newestId
    }

    private func checkStatusWhenNotCheckedIn() -> Completable {

        traceIdCoreRepo
            .restore()
            .observe(on: LucaScheduling.backgroundScheduler)
            .flatMapCompletable { traces -> Completable in
                if traces.count == 0 {
                    self.log("Traces are empty", entryType: .debug)
                    return Completable.empty()
                }

                let traceIds: [TraceId]
                do {
                    traceIds = try traces.map { try self.getOrCreateTraceId(core: $0) }
                } catch let error {
                    self.log("Unable to getOrCreateTraceID. Error: \(error)", entryType: .error)
                    throw TraceIdServiceError.unableToBuildTraceId
                }

                return self.backend.fetchInfo(traceIds: traceIds)
                    .asSingle()
                    .asObservable()
                    .flatMap { traceInfos in
                        self.traceInfoRepo.store(objects: traceInfos)
                    }
                    .flatMap { _ in self.currentTraceInfo }
                    .do(onNext: { traceInfo in
                        if traceInfo.isCheckedIn {
                            let userInfo: [String: Any] = ["traceInfo": traceInfo]
                            NotificationCenter.default.post(Notification(name: Notification.Name(self.onCheckIn), object: self, userInfo: userInfo))
                        }
                    })
                    .ignoreElementsAsCompletable()
                    .catch { (error) -> Completable in
                        guard let error = error as? BackendError<FetchTraceInfoError> else {
                            throw TraceIdServiceError.unknown
                        }
                        if let backendError = error.backendError,
                           case FetchTraceInfoError.notFound = backendError {
                            return Completable.empty()
                        } else if let networkError = error.networkLayerError {
                            self.log("Error Checking status when NOT checked in. Error: \(error)", entryType: .error)
                            throw TraceIdServiceError.networkError(error: networkError)
                        } else {
                            self.log("Error Checking status when NOT checked in. Error: \(error)", entryType: .error)
                            throw TraceIdServiceError.unknown
                        }
                    }
            }
    }

    private func checkStatusWhenCheckedIn(currentTraceId: TraceId) -> Completable {
        print("Current traceId: \(currentTraceId.traceIdString)")
        return traceInfoRepo.restore()
            .map { traceInfos in traceInfos.first(where: { $0.traceId == currentTraceId.traceIdString }) }
            .catchAndReturn(nil)
            .flatMapCompletable { currentTraceInfo in
                self.backend.fetchInfo(traceId: currentTraceId)
                    .asSingle()
                    .flatMap(self.traceInfoRepo.store)
                    .flatMapCompletable { updatedTraceInfo in
                        if !updatedTraceInfo.isCheckedIn {
                            return self.performCheckOut(triggerCheckOutEvent: true, traceInfoToCheckOut: updatedTraceInfo)
                        }
                        return Completable.empty()
                    }
                    .catch { error in
                        guard let interpretedError = error as? BackendError<FetchTraceInfoError> else {
                            throw error
                        }
                        if let backendError = interpretedError.backendError,
                           case FetchTraceInfoError.notFound = backendError {
                            return self.performCheckOut(triggerCheckOutEvent: true, traceInfoToCheckOut: currentTraceInfo)
                        }
                        self.log("Error Checking status when checked in. Error: \(error)", entryType: .error)
                        if let networkError = interpretedError.networkLayerError {
                            throw TraceIdServiceError.networkError(error: networkError)
                        }
                        throw error
                    }
            }
    }

    private func performCheckOut(triggerCheckOutEvent: Bool, traceInfoToCheckOut: TraceInfo? = nil) -> Completable {
        var checkedOutTraceInfo = traceInfoToCheckOut

        if var traceInfo = traceInfoToCheckOut,
           traceInfo.checkOutDate == nil {
            traceInfo = closeNow(traceInfo: traceInfo)
            checkedOutTraceInfo = traceInfo
        }
        return Maybe.from { checkedOutTraceInfo }
            .flatMap { self.traceInfoRepo.store(object: $0).asMaybe() }
            .asObservable()
            .ignoreElementsAsCompletable()
            .andThen(Completable.from {
                if triggerCheckOutEvent {
                    var userInfo: [String: Any]?
                    if let traceInfo = checkedOutTraceInfo {
                        userInfo = ["traceInfo": traceInfo]
                    }
                    NotificationCenter.default.post(Notification(name: Notification.Name(self.onCheckOut), object: self, userInfo: userInfo))
                }
                self.cachedTraceIds = [:]
                self.removeAdditionalData()
                self.disposeData(clearTraceHistory: false)
        })
    }

    // MARK: - Data sanity logic

    /// Takes all open trace infos and asks backend if those are correct.
    /// This was needed due to migration from v1.6.0
    private func checkCorrectnessOfLocalTraceInfoData() -> Completable {

        // It should run only once in a runtime
        if consistencyCheckAlreadyRun {
            return Completable.empty()
        }

        return removeExpiredCheckIns()
            .andThen(closeOldCheckIns())
            .do(onCompleted: {
                self.consistencyCheckAlreadyRun = true
            })
    }

    /// Sets the checkOut date to checkInDate + 24h if not set already.
    ///
    /// If the checkinDate is not so old, nothing will be changed.
    /// If the checkOutDate is not nil, nothing will be changed either.
    private func closeIfOlderThanOneDay(traceInfo: TraceInfo) -> TraceInfo {
        if traceInfo.checkout == nil {
            let now = Date()
            let upperBound = Calendar.current.date(byAdding: .day, value: 1, to: traceInfo.checkInDate) ?? now
            /// If upper bound has been reached
            if now > upperBound {
                var checkedOutTraceInfo = traceInfo
                checkedOutTraceInfo.checkout = Int(upperBound.timeIntervalSince1970)
                return checkedOutTraceInfo
            }
        }
        return traceInfo
    }

    private func closeNow(traceInfo: TraceInfo) -> TraceInfo {
        var closedAfterOneDay = closeIfOlderThanOneDay(traceInfo: traceInfo)
        if closedAfterOneDay.checkout == nil {
            closedAfterOneDay.checkout = Int(Date().timeIntervalSince1970)
        }
        return closedAfterOneDay
    }

    /// Reads all saved TraceInfos and checks out all of those who are not closed and are older than 24h.
    ///
    /// It leaves out the newest one as this is the actual checkin that has to be checked out properly.
    private func closeOldCheckIns() -> Completable {
        traceInfoRepo.restore()
            .map { array in array.filter { $0.isCheckedIn } }           // Get only checked in traceInfos
            .map { array in array.sorted { $0.checkin < $1.checkin } }  // Sort ascending by check in
            .map { array -> [TraceInfo] in
                var modifiedArray = array
                _ = modifiedArray.popLast()                             // Remove the newest one
                return modifiedArray
            }
            .map { array in array.map(self.closeNow) }                  // Close all traceInfos
            .flatMap(self.traceInfoRepo.store)
            .asCompletable()
    }

    /// Removes all traceInfos older than 28 days.
    private func removeExpiredCheckIns() -> Completable {
        let today = Date()
        guard let lowerBound = Calendar.current.date(byAdding: .day, value: -28, to: today) else {
            return Completable.empty() // Will not happen, just for unwrapping Date optional
        }
        return traceInfoRepo.restore()
            .map { array in array.filter { $0.checkInDate < lowerBound } }
            .map { array in array.map { $0.identifier ?? 0 } }
            .flatMapCompletable(self.traceInfoRepo.remove)
    }

}

extension TraceIdService: UnsafeAddress, LogUtil {}
