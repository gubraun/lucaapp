import Foundation
import RxSwift

struct PrivateMeetingData: Codable {
    var keyIndex: Int
    var createdAt: Date
    var deletedAt: Date?
    var guests: [PrivateMeetingGuest] = []
    var ids: PrivateMeetingIds
}

extension PrivateMeetingData {
    var isOpen: Bool {
        return deletedAt == nil || deletedAt!.timeIntervalSince1970 > Date().timeIntervalSince1970
    }
}

// Service that checks the host of a private meeting in and out.
public class PrivateMeetingService {

    let onHostCheckIn = "onHostCheckIn"
    let onHostCheckOut = "onHostCheckOut"

    let onMeetingCreated = "onMeetingCreated"
    let onMeetingClosed = "onMeetingClosed"

    private let privateKeysHistoryRepo: LocationPrivateKeyHistoryRepository
    private let preferences: Preferences
    private let backend: BackendLocationV3
    private let traceIdAdditionalDataBuilder: TraceIdAdditionalDataBuilderV3

    private var meetings: [PrivateMeetingData] {
        get {
            preferences.retrieve(key: "meetingsData", type: [PrivateMeetingData].self) ?? []
        }
        set {
            preferences.store(newValue, key: "meetingsData")
        }
    }

    var currentMeeting: PrivateMeetingData? {
        meetings.filter { $0.isOpen }.first
    }

    init(privateKeys: LocationPrivateKeyHistoryRepository,
         preferences: Preferences,
         backend: BackendLocationV3,
         traceIdAdditionalDataBuilder: TraceIdAdditionalDataBuilderV3) {
        self.privateKeysHistoryRepo = privateKeys
        self.preferences = preferences
        self.backend = backend
        self.traceIdAdditionalDataBuilder = traceIdAdditionalDataBuilder
    }

    func createMeeting(completion: @escaping (PrivateMeetingData) -> Void, failure: @escaping (Error) -> Void) {
        guard let key = KeyFactory.createPrivate(tag: "", type: .ecsecPrimeRandom, sizeInBits: 256) else {
            failure(CryptoError.privateKeyNotRetrieved)
            return
        }
        let keyIndex = privateKeysHistoryRepo.indices.count
        do {
            try privateKeysHistoryRepo.store(key: key, index: keyIndex)
        } catch let error {
            failure(error)
            return
        }

        guard let publicKey = KeyFactory.derivePublic(from: key) else {
            failure(CryptoError.publicKeyNotRetrieved)
            return
        }

        backend.createPrivateMeeting(publicKey: publicKey)
            .execute { (ids) in
                let privateMeeting = PrivateMeetingData(keyIndex: keyIndex, createdAt: Date(), ids: ids)

                self.refreshInstance(meeting: privateMeeting)

                NotificationCenter.default.post(Notification(
                                                    name: Notification.Name(self.onMeetingCreated),
                                                    object: self,
                                                    userInfo: ["meeting": privateMeeting]))
                completion(privateMeeting)

            } failure: { (error) in
                self.privateKeysHistoryRepo.remove(index: keyIndex)
                failure(error)
            }
    }

    func close(meeting: PrivateMeetingData, completion: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        backend.deletePrivateMeeting(accessId: meeting.ids.accessId).execute {

            var copiedMeeting = meeting
            copiedMeeting.deletedAt = Date()
            self.refreshInstance(meeting: copiedMeeting)

            NotificationCenter.default.post(Notification(
                                                name: Notification.Name(self.onMeetingClosed),
                                                object: self,
                                                userInfo: ["meeting": copiedMeeting]))
            completion()
        } failure: { (error) in
            failure(error)
        }
    }

    func refresh(meeting: PrivateMeetingData, completion: @escaping (PrivateMeetingData) -> Void, failure: @escaping (Error) -> Void) {
        backend.fetchLocationGuests(accessId: meeting.ids.accessId)
            .execute { (guests) in

                var copiedMeeting = meeting
                copiedMeeting.guests = guests
                self.refreshInstance(meeting: copiedMeeting)

                completion(copiedMeeting)
            } failure: { (error) in
                failure(error)
            }
    }

    func decrypt(guestData: PrivateMeetingGuest, meetingKeyIndex: Int) throws -> PrivateMeetingQRCodeV3AdditionalData {
        guard let guestEncryptedData = guestData.data else {
            throw NSError(domain: "No data available", code: 0, userInfo: nil)
        }
        let venuePrivKey = try privateKeysHistoryRepo.restore(index: meetingKeyIndex)

        guard let keyData = Data(base64Encoded: guestEncryptedData.publicKey),
              let key = KeyFactory.create(from: keyData, type: .ecsecPrimeRandom, keyClass: .public),
              let iv = Data(base64Encoded: guestEncryptedData.iv),
              let encData = Data(base64Encoded: guestEncryptedData.data) else {
            throw NSError(domain: "Failed preparing data", code: 0, userInfo: nil)
        }

        let parsed = try traceIdAdditionalDataBuilder.decrypt(
            destination: PrivateMeetingQRCodeV3AdditionalData.self,
            venuePrivKey: ValueKeySource(key: venuePrivKey),
            userPubKey: ValueKeySource(key: key),
            data: encData,
            iv: iv)
        return parsed
    }

    /// It replaces the instance from the array based on the instanceId
    private func refreshInstance(meeting: PrivateMeetingData) {
        var tempMeetings = self.meetings
        tempMeetings.removeAll(where: { $0.ids.locationId == meeting.ids.locationId })
        tempMeetings.append(meeting)
        meetings = tempMeetings
    }
}

extension PrivateMeetingService: LogUtil, UnsafeAddress {}

extension PrivateMeetingService {

    var onMeetingCreatedRx: Observable<PrivateMeetingData> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onMeetingCreated), object: self)
            .map { $0.userInfo?["meeting"] as? PrivateMeetingData }
            .unwrapOptional()
            .logError(self, "onMeetingCreatedRx")
    }

    var onMeetingClosedRx: Observable<PrivateMeetingData> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onMeetingClosed), object: self)
            .map { $0.userInfo?["meeting"] as? PrivateMeetingData }
            .unwrapOptional()
            .logError(self, "onMeetingClosedRx")
    }
}

extension PrivateMeetingService {
    func createMeeting() -> Single<PrivateMeetingData> {
        Single<PrivateMeetingData>.create { (observer) -> Disposable in

            self.createMeeting { (meeting) in
                observer(.success(meeting))
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    func close(meeting: PrivateMeetingData) -> Completable {
        Completable.create { (observer) -> Disposable in

            self.close(meeting: meeting) {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    func refresh(meeting: PrivateMeetingData) -> Single<PrivateMeetingData> {
        Single<PrivateMeetingData>.create { (observer) -> Disposable in

            self.refresh(meeting: meeting) { (meeting) in
                observer(.success(meeting))
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
}
