import Foundation

class RetrieveKeyAsyncOperationV3: BackendAsyncDataOperation<KeyValueParameters, PublicKeyFetchResultV3, RetrieveDailyKeyError> {

    init(backendAddress: BackendAddressV3, keyId: Int) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("keys")
            .appendingPathComponent("daily")
            .appendingPathComponent("\(keyId)")

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [400: .notFound])
    }

    override func execute(completion: @escaping (PublicKeyFetchResultV3) -> Void, failure: @escaping (BackendError<RetrieveDailyKeyError>) -> Void) -> (() -> Void) {
        return super.execute { (result) in
            if result.parsedKey == nil {
                failure(BackendError<RetrieveDailyKeyError>(backendError: .unableToParse))
            } else {
                completion(result)
            }
        } failure: { (error) in
            failure(error)
        }

    }
}
