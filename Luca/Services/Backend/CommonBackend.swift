import Foundation
import Alamofire

protocol BackendAddress {
    var host: URL { get }
    var apiUrl: URL { get }
    var privacyPolicyUrl: URL? { get }
}

class BaseBackendSMSVerification: BackendSMSVerification {

    private let backendAddress: BackendAddress
    init(backendAddress: BackendAddress) {
        self.backendAddress = backendAddress
    }

    func requestChallenge(phoneNumber: String) -> AsyncDataOperation<BackendError<RequestChallengeError>, RequestChallengeResult> {
        SMSRequestChallengeAsyncDataOperation(backendAddress: backendAddress, phoneNumber: phoneNumber)
    }
    func verify(tan: String, challenge: String) -> AsyncOperation<BackendError<VerifyChallengeError>> {
        VerifyChallengeRequestAsyncOperation(backendAddress: backendAddress, challengeId: challenge, tan: tan)
    }
    func verify(tan: String, challenges: [String]) -> AsyncDataOperation<BackendError<VerifyChallengeError>, String> {
        VerifyChallengeBulkRequestAsyncOperation(backendAddress: backendAddress, challengeIds: challenges, tan: tan)
    }
}

class CommonBackendMisc: BackendMisc {

    private let backendAddress: BackendAddress

    init(backendAddress: BackendAddress) {
        self.backendAddress = backendAddress
    }

    func fetchHealthDepartment(healthDepartmentId: UUID) -> AsyncDataOperation<BackendError<FetchHealthDepartmentError>, HealthDepartment> {
        FetchDepartmentAsyncOperation(backendAddress: backendAddress, departmentId: healthDepartmentId)
    }

    func fetchScanner(scannerId: String) -> AsyncDataOperation<BackendError<FetchScannerError>, ScannerInfo> {
        FetchScannerAsyncOperation(backendAddress: backendAddress, scannerId: scannerId)
    }

    func fetchSupportedVersions() -> AsyncDataOperation<BackendError<FetchSupportedVersionError>, SupportedVersions> {
        FetchSupportedVersionsAsyncOperation(backendAddress: backendAddress)
    }

    func fetchAccessedTraces() -> AsyncDataOperation<BackendError<FetchAccessedTracesError>, [AccessedTrace]> {
        FetchAccessedTracesAsyncDataOperation(backendAddress: backendAddress)
    }

    func fetchTestProviderKeys() -> AsyncDataOperation<BackendError<FetchTestProviderKeysError>, [TestProviderKey]> {
        FetchTestProviderKeysDataAsyncOperation(backendAddress: backendAddress)
    }

    func redeemDocument(hash: Data, tag: Data) -> AsyncOperation<BackendError<RedeemDocumentError>> {
        RedeemDocumentAsyncOperation(backendAddress: backendAddress, hash: hash, tag: tag)
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
