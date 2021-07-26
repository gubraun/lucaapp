import Foundation
import Alamofire

#if DEBUG
import Mocker
#endif

struct RequestChallengeResult: Codable {
    var smsLimitInfo: SMSLimit
    var challenge: String
}

enum RequestChallengeError: RequestError {
    case validationFailed
    case smsGateFailure
    case smsLimitReached(info: SMSLimit)
}

extension RequestChallengeError {
    var errorDescription: String? {
        switch self {
        case .smsLimitReached(info: _):
            return L10n.Verification.PhoneNumber.LimitReached.message
        default:
            return L10n.Verification.PhoneNumber.requestFailure
        }
    }
    var localizedTitle: String {
        switch self {
        case .smsLimitReached(info: _):
            return L10n.Verification.PhoneNumber.LimitReached.title
        default:
            return L10n.Navigation.Basic.error
        }
    }
}

class SMSRequestChallengeAsyncDataOperation: AsyncDataOperation<BackendError<RequestChallengeError>, RequestChallengeResult> {

    private let url: URL
    private let parameters: [String: String]
    private var session: Session!

    init(backendAddress: BackendAddress, phoneNumber: String) {

        url = backendAddress.apiUrl
            .appendingPathComponent("sms")
            .appendingPathComponent("request")

        session = LucaAlamofireSessionBuilder.build(pinnedCertificateHost: url.host ?? "", disableCache: true)

        self.parameters = ["phone": phoneNumber]
    }

    // swiftlint:disable:next function_body_length
    override func execute(completion: @escaping (RequestChallengeResult) -> Void, failure: @escaping (BackendError<RequestChallengeError>) -> Void) -> (() -> Void) {
        let request = session.request(
                url,
                method: .post,
                parameters: parameters,
                encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()),
                headers: ["User-Agent": userAgent, "Authorization": authorizationContent])
            .map(code: 400, to: RequestChallengeError.validationFailed)
            .map(code: 500, to: RequestChallengeError.smsGateFailure)

        #if DEBUG
        mockForTesting()
        #endif

        let startedRequest = request
            .validate(statusCode: 200...299)
            .responseDict { (response) in
                _ = self // capture self

                guard let responseHeaders = response.response?.headers else {
                    failure(BackendError<RequestChallengeError>(networkLayerError: .invalidResponsePayload))
                    return
                }

                guard let rateLimitResetString = responseHeaders.value(for: "X-RateLimit-Reset"),
                      let rateLimitReset = Int(rateLimitResetString),
                      let rateLimitRemainingString = responseHeaders.value(for: "X-RateLimit-Remaining"),
                      let remaining = Int(rateLimitRemainingString),
                      let rateLimitTotalString = responseHeaders.value(for: "X-RateLimit-Limit"),
                      let rateLimitTotal = Int(rateLimitTotalString) else {
                    failure(BackendError<RequestChallengeError>(networkLayerError: .invalidResponsePayload))
                    return
                }

                let rateLimitInfos = SMSLimit(reset: rateLimitReset, remaining: remaining, limit: rateLimitTotal)

                if response.response?.statusCode == 429 || rateLimitInfos.remaining < 0 {
                    let error = BackendError<RequestChallengeError>(backendError: .smsLimitReached(info: rateLimitInfos))
                    failure(error)
                    return
                }

                if let error = response.retrieveBackendError(RequestChallengeError.self) {
                    failure(error)
                    return
                }

                guard let dict = response.retrieveData(failure: failure) else { return }
                guard let challenge = dict["challengeId"] as? String else {
                    failure(BackendError<RequestChallengeError>(networkLayerError: .invalidResponsePayload))
                    return
                }

                let result = RequestChallengeResult(smsLimitInfo: rateLimitInfos, challenge: challenge)
                completion(result)
            }

        return { startedRequest.cancel() }
    }
    #if DEBUG
    private func mockForTesting() {
        // To mock AF requests for testing
        if let statusCode = testedBackendError {
            // swiftlint:disable:next force_try
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(
                url: url,
                dataType: .json,
                statusCode: statusCode,
                data: [Mock.HTTPMethod(rawValue: HTTPMethod.post.rawValue)!: mockedData],
                additionalHeaders: [
                    "X-RateLimit-Reset": "1614779558",
                    "X-RateLimit-Remaining": "12",
                    "X-RateLimit-Limit": "50"])
            mock.register()
        }
    }
    #endif
}
