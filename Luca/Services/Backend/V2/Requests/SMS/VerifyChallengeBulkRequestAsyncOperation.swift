import Foundation
import Alamofire

struct VerifyChallengeBulkParams: Codable {
    var challengeIds: [String]
    var tan: String
}

class VerifyChallengeBulkRequestAsyncOperation: MappedBackendAsyncDataOperation<VerifyChallengeBulkParams, String, VerifyChallengeError> {
    
    init(backendAddress: BackendAddress, challengeIds: [String], tan: String) {
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("sms")
            .appendingPathComponent("verify")
            .appendingPathComponent("bulk")
        
        let parameters = VerifyChallengeBulkParams(challengeIds: challengeIds, tan: tan)
        
        super.init(url: fullUrl,
                   method: .post,
                   parameters: parameters,
                   errorMappings: [403: .smsTANInvalid])
    }
    
    override func map(dict: [String : Any]) throws -> String {
        if let challengeId = dict["challengeId"] as? String {
            return challengeId
        }
        throw NetworkError.invalidResponsePayload
    }
}
