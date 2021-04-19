import Foundation
import RxSwift

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

    // MARK: - event names
    public let onCheckIn: String = "TraceIdService.onCheckIn"
    public let onCheckOut: String = "TraceIdService.onCheckOut"

    // MARK: - Persisted properties
    private(set) var currentTraces: [TraceIdCore] {
        get {
            let now = Date()
            return (preferences.retrieve(key: "currentTraces", type: [TraceIdCore].self) ?? [])
                .filter { now.timeIntervalSince1970 - $0.date.timeIntervalSince1970 < 3600.0 } // Only traceIds from the last hour
        }
        set {
            preferences.store(newValue, key: "currentTraces")
        }
    }

    private var traceInfos: [TraceInfo] {
        get {
            preferences.retrieve(key: "traceInfos", type: [TraceInfo].self) ?? []
        }
        set {
            preferences.store(newValue, key: "traceInfos")
        }
    }

    private(set) var currentLocationInfo: Location? {
        get {
            preferences.retrieve(key: "location", type: Location.self)
        }
        set {
            if let value = newValue {
                preferences.store(value, key: "location")
            } else {
                preferences.remove(key: "location")
            }
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

    var currentTraceInfo: TraceInfo? {
        return traceInfos.filter { $0.isCheckedIn }.sorted(by: { $0.checkin > $1.checkin }).first
    }

    var checkedInTraceId: TraceId? {
        return currentTraceInfo?.traceIdData
    }

    /// It returns current known status without checking with backend
    var isCurrentlyCheckedIn: Bool {
        return checkedInTraceId != nil
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
         locationRepo: LocationRepo) {

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
    }

    public func getOrCreateQRCode() throws -> QRCodePayloadV3 {
        let newOnes = currentTraces.filter { Date().timeIntervalSince1970 - $0.date.timeIntervalSince1970 < 60.0 }
        if let first = newOnes.first {
            return try buildQRCode(core: first)
        }
        return try generateQRCode()
    }

    /// Fetches current status and updates internals. It does not fetch location data, it should be fetched explicit.
    public func fetchTraceStatus(completion: @escaping () -> Void, failure: @escaping (TraceIdServiceError) -> Void) {

        if let currentTraceId = self.currentTraceInfo?.traceIdData {
            checkStatusWhenCheckedIn(currentTraceId: currentTraceId, completion: completion, failure: failure)
        } else {
            checkStatusWhenNotCheckedIn(completion: completion, failure: failure)
        }
    }

    /// Fetches the informations. Those informations will be later persisted in `TraceIdService.currentLocationInfo` so it can be accessed later event without internet
    public func fetchCurrentLocationInfo() -> Single<Location> {
        Completable.from {
            if !self.isCurrentlyCheckedIn {
                throw TraceIdServiceError.notCheckedIn
            }
        }
        .andThen(Single.from {
            if let locationId = self.currentTraceInfo?.parsedLocationId {
                return locationId
            }
            throw TraceIdServiceError.unableToRetrieveLocationID
        })
        .asObservable()
        .flatMap { self.backendLocation.fetchLocation(locationId: $0).asSingle() }
        .flatMap { self.locationRepo.store(object: $0) }
        .map { location in
            if let privateMeeting = self.additionalData as? PrivateMeetingQRCodeV3AdditionalData {
                var locationInfo = location
                locationInfo.groupName = "\(privateMeeting.fn) \(privateMeeting.ln)"
                return locationInfo
            }
            return location
        }
        .asSingle()
        .do(onSuccess: { self.currentLocationInfo = $0 })
    }

    public func checkOut(completion: @escaping () -> Void, failure: @escaping (TraceIdServiceError) -> Void) {
        guard let currentTraceId = self.checkedInTraceId else {
            failure(TraceIdServiceError.notCheckedIn)
            return
        }

        backend.checkOut(traceId: currentTraceId, timestamp: Date())
            .execute {
                self.performCheckOut()
                completion()
            } failure: { error in
                if let networkError = error.networkLayerError {
                    failure(TraceIdServiceError.networkError(error: networkError))
                    return
                }
                if let backendError = error.backendError {
                    switch backendError {
                    default:
                        failure(TraceIdServiceError.unableToCheckOut)
                    // All those cases shouldn't be of interest of the user of this service (I guess)
//                    case .checkInTimeLargerThanCheckOutTime:
//                    case .failedToBuildCheckOutPayload(let failedToBuildCheckoutPayloadError):
//                    case .invalidInput:
//                    case .invalidSignature:
//                    case .notFound:
                    }
                    return
                }
                failure(TraceIdServiceError.unknown)
            }
    }

    public func checkInRx(selfCheckin: SelfCheckin) -> Completable {
        let checkInLogic = self.fetchScanner(for: selfCheckin)
            .asObservable()

            // Wrap internal error to another one.
            // If scanner is not available and this error is not faulted by system or connectivity,
            // its a signal that the event is outdated
            .do(onError: { error in
                if let backendError = error as? BackendError<FetchScannerError>,
                   backendError.backendError != nil {
                    throw TraceIdServiceError.unableToCheckInToOutdatedEvent
                }
            })

            .flatMap { (scannerInfo: ScannerInfo) -> Observable<Never> in
                guard let qrCode = try? self.getOrCreateQRCode() else {
                    return Observable.error(NSError(domain: "Couldn't obtain qr code", code: 0, userInfo: nil))
                }
                guard let keyData = Data(base64Encoded: scannerInfo.publicKey) else {
                    return Observable.error(NSError(domain: "Couldn't obtain key data", code: 0, userInfo: nil))
                }
                guard let key = KeyFactory.create(from: keyData, type: .ecsecPrimeRandom, keyClass: .public) else {
                    return Observable.error(NSError(domain: "Couldn't create key from key data", code: 0, userInfo: nil))
                }
                let checkin = self.backend.checkIn(qrCode: qrCode, venuePubKey: ValueKeySource(key: key), scannerId: scannerInfo.scannerId).asCompletable()
                if let traceId = qrCode.parsedTraceId {
                    return checkin.andThen(
                        self.updateAdditionalData(for: selfCheckin, traceId: traceId, venuePubKey: key)
                        .asObservable()
                    )
                } else {
                    return checkin.asObservable()
                }
            }
            .asObservable()
            .ignoreElements()

        return Completable
            .from {
                if self.isCurrentlyCheckedIn {
                    throw TraceIdServiceError.userCheckedInAlready
                }
            }
            .andThen(Completable.from {
                if self.privateMeetingService.currentMeeting != nil {
                    throw TraceIdServiceError.privateMeetingRunning
                }
            })
            .andThen(checkInLogic)
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
            self.traceInfoRepo
                .removeAll()
                .debug("TraceInfo removal")
                .logError(self, "TraceInfo removal")
                .subscribe()
        }
        self.currentTraces = []
        self.traceInfos = []
        self.removeAdditionalData()
        self.currentLocationInfo = nil
        self.ePubKeyRepo.removeAll()
        self.ePrivKeyRepo.removeAll()
    }

    // MARK: - private helper
    private func generateQRCode() throws -> QRCodePayloadV3 {
        let newestKeyId = try retrieveNewestKeyId()
        let traceIdCore = TraceIdCore(date: Date(), keyId: UInt8(newestKeyId.keyId))

        let keyIndex = Int(traceIdCore.date.lucaTimestampInteger)
        let privKeyPresent = (try? ePrivKeyRepo.restore(index: keyIndex)) != nil
        let pubKeyPresent = (try? ePubKeyRepo.restore(index: keyIndex)) != nil
        if !privKeyPresent || !pubKeyPresent {
            guard let privKey = KeyFactory.createPrivate(tag: "PrivKey", type: .ecsecPrimeRandom, sizeInBits: 256) else {
                throw NSError(domain: "Couldn't generate ephemeral private key", code: 0, userInfo: nil)
            }
            guard let pubKey = KeyFactory.derivePublic(from: privKey) else {
                throw NSError(domain: "Couldn't derive public key", code: 0, userInfo: nil)
            }
            try ePrivKeyRepo.store(key: privKey, index: keyIndex)
            try ePubKeyRepo.store(key: pubKey, index: keyIndex)
        }
        let code = try buildQRCode(core: traceIdCore)
        var traces = currentTraces
        traces.append(traceIdCore)
        currentTraces = traces
        return code
    }

    private func buildQRCode(core: TraceIdCore) throws -> QRCodePayloadV3 {
        let userId = try retrieveUserId()
        let code = try qrCodeGenerator.build(for: core, userID: userId)
        return code
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

    private func checkStatusWhenNotCheckedIn(completion: @escaping () -> Void, failure: @escaping (TraceIdServiceError) -> Void) {

        // Trace ID computing does not have to be computed on the main thread
        DispatchQueue.global(qos: .default).async {

            let traces = self.currentTraces
            if traces.count == 0 {
                self.log("Traces are empty", entryType: .debug)
                completion()
                return
            }

            let traceIds: [TraceId]
            do {
                traceIds = try traces.map { try self.getOrCreateTraceId(core: $0) }
            } catch let error {
                self.log("Unable to getOrCreateTraceID. Error: \(error)", entryType: .error)
                failure(TraceIdServiceError.unableToBuildTraceId)
                return
            }

            print("checking following traceIds: \(traceIds.map { $0.traceIdString })")

            self.backend.fetchInfo(traceIds: traceIds)
                .execute { (traceInfos) in
                    self.traceInfos = traceInfos
                    if self.isCurrentlyCheckedIn {
                        NotificationCenter.default.post(Notification(name: Notification.Name(self.onCheckIn), object: self, userInfo: nil))
                    }
                    completion()
                } failure: { (error) in

                    // This error is an expected value in case user hasn't been checked in

                    if let backendError = error.backendError,
                       case FetchTraceInfoError.notFound = backendError {
                        completion()
                    } else if let networkError = error.networkLayerError {
                        self.log("Error Checking status when NOT checked in. Error: \(error)", entryType: .error)
                        failure(TraceIdServiceError.networkError(error: networkError))
                    } else {
                        self.log("Error Checking status when NOT checked in. Error: \(error)", entryType: .error)
                        failure(TraceIdServiceError.unknown)
                    }
                }
        }
    }

    private func checkStatusWhenCheckedIn(currentTraceId: TraceId, completion: @escaping () -> Void, failure: @escaping (TraceIdServiceError) -> Void) {
        print("Current traceId: \(currentTraceId.traceIdString)")
        backend.fetchInfo(traceId: currentTraceId)
            .execute { (traceInfo) in
                if !traceInfo.isCheckedIn {
                    self.performCheckOut()
                }
                completion()
            } failure: { (error) in
                if let backendError = error.backendError,
                   case FetchTraceInfoError.notFound = backendError {
                    self.performCheckOut()
                }
                self.log("Error Checking status when checked in. Error: \(error)", entryType: .error)
                if let networkError = error.networkLayerError {
                    failure(TraceIdServiceError.networkError(error: networkError))
                } else {
                    failure(TraceIdServiceError.unknown)
                }
            }
    }

    private func performCheckOut() {
        let hasBeenCheckedIn = isCurrentlyCheckedIn
        let capturedTraceInfos = traceInfos
        self.traceInfos = []

        traceInfoRepo
            .store(objects: capturedTraceInfos)
            .debug("TraceInfo Storing 0")
            .logError(self, "TraceInfo Storing")
            .subscribe() // Doesn't need to add to dispose bag as this stream ends and disposes automatically

        self.cachedTraceIds = [:]
        if hasBeenCheckedIn {
            NotificationCenter.default.post(Notification(name: Notification.Name(self.onCheckOut), object: self, userInfo: nil))
        }
        self.currentLocationInfo = nil
        self.removeAdditionalData()

        self.disposeData(clearTraceHistory: false)
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

}

extension TraceIdService: UnsafeAddress, LogUtil {}
