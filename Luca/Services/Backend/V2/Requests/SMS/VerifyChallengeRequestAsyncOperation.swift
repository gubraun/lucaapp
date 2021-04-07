import Foundation
import Alamofire

enum VerifyChallengeError: RequestError {
    case smsTANInvalid
}

extension VerifyChallengeError {
    var errorDescription: String? {
        switch self {
        case .smsTANInvalid:
            return L10n.Verification.PhoneNumber.failureMessage
        }
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class VerifyChallengeRequestAsyncOperation: BackendAsyncOperation<[String: String], VerifyChallengeError> {
    
    init(backendAddress: BackendAddress, challengeId: String, tan: String) {
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("sms")
            .appendingPathComponent("verify")
        
        let parameters: [String: String] = [
            "challengeId": challengeId,
            "tan": tan
        ]
        
        super.init(url: fullUrl,
                   method: .post,
                   parameters: parameters,
                   errorMappings: [403: .smsTANInvalid])
    }
}
