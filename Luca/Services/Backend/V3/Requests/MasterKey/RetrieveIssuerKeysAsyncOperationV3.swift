import Foundation

struct IssuerKeysFetchResultV3: Codable {
    var issuerId: String
    var name: String
    var publicHDEKP: String
    var publicHDSKP: String
}

extension IssuerKeysFetchResultV3 {
    var parsedPublicHDSKP: SecKey? {
        guard let keyData = Data(base64Encoded: publicHDSKP),
              let key = KeyFactory.create(from: keyData, type: .ecsecPrimeRandom, keyClass: .public) else {
            return nil
        }
        return key
    }
}

class RetrieveIssuerKeysAsyncOperationV3: BackendAsyncDataOperation<KeyValueParameters, IssuerKeysFetchResultV3, RetrieveDailyKeyError> {
    
    init(backendAddress: BackendAddressV3, issuerId: String) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("keys")
            .appendingPathComponent("issuers")
            .appendingPathComponent(issuerId)
        
        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
    
    override func execute(completion: @escaping (IssuerKeysFetchResultV3) -> Void, failure: @escaping (BackendError<RetrieveDailyKeyError>) -> Void) -> (() -> Void) {
        return super.execute { (result) in
            if result.parsedPublicHDSKP == nil {
                failure(BackendError<RetrieveDailyKeyError>(backendError: .unableToParse))
            } else {
                completion(result)
            }
        } failure: { (error) in
            failure(error)
        }
    }
}
