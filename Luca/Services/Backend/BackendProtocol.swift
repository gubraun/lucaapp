import Foundation

struct SMSLimit: Codable {
    var reset: Int
    var remaining: Int
    var limit: Int
}

extension SMSLimit {
    var resetDate: Date {
        Date(timeIntervalSince1970: Double(reset))
    }
}

protocol BackendSMSVerification {

    func requestChallenge(phoneNumber: String) -> AsyncDataOperation<BackendError<RequestChallengeError>, RequestChallengeResult>
    func verify(tan: String, challenge: String) -> AsyncOperation<BackendError<VerifyChallengeError>>
    func verify(tan: String, challenges: [String]) -> AsyncDataOperation<BackendError<VerifyChallengeError>, String>
}

protocol BackendMisc {

    func fetchHealthDepartment(healthDepartmentId: UUID) -> AsyncDataOperation<BackendError<FetchHealthDepartmentError>, HealthDepartment>
    func fetchScanner(scannerId: String) -> AsyncDataOperation<BackendError<FetchScannerError>, ScannerInfo>
    func fetchSupportedVersions() -> AsyncDataOperation<BackendError<FetchSupportedVersionError>, SupportedVersions>
    func fetchAccessedTraces() -> AsyncDataOperation<BackendError<FetchAccessedTracesError>, [AccessedTrace]>
    func fetchTestProviderKeys() -> AsyncDataOperation<BackendError<FetchTestProviderKeysError>, [TestProviderKey]>
    func redeemDocument(hash: Data, tag: Data) -> AsyncOperation<BackendError<RedeemDocumentError>>
}

struct PrivateMeetingIds: Codable {
    var locationId: String
    var scannerId: String
    var accessId: String
}

struct PrivateMeetingGuest: Codable {
    var traceId: String
    var checkin: Int
    var checkout: Int?
    var data: PrivateMeetingGuestData?
}

extension PrivateMeetingGuest {
    var isCheckedIn: Bool {
        return checkout == nil || Double(checkout!) > Date().timeIntervalSince1970
    }
}

struct PrivateMeetingGuestData: Codable {
    var data: String
    var iv: String
    var mac: String
    var publicKey: String
}

protocol BackendLocation {

    func fetchLocation(locationId: UUID) -> AsyncDataOperation<BackendError<FetchLocationError>, Location>
    func createPrivateMeeting(publicKey: SecKey) -> AsyncDataOperation<BackendError<CreatePrivateMeetingError>, PrivateMeetingIds>
    func fetchLocationGuests(accessId: String) -> AsyncDataOperation<BackendError<FetchLocationGuestsError>, [PrivateMeetingGuest]>
    func deletePrivateMeeting(accessId: String) -> AsyncOperation<BackendError<DeletePrivateMeetingError>>
}

protocol BackendDailyKey {
    associatedtype ErrorType: Error

    func retrieveDailyPubKey() -> AsyncDataOperation<ErrorType, (Int, SecKey)>
}
