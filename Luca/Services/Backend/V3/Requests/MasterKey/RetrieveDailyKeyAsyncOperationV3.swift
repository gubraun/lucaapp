import Foundation

struct PublicKeyFetchResultV3: Codable {
    var keyId: Int
    var issuerId: String
    var publicKey: String
    var createdAt: Int
    var signature: String
}

extension PublicKeyFetchResultV3 {
    var parsedKey: SecKey? {
        guard let keyData = Data(base64Encoded: publicKey) else {
            return nil
        }
        guard let key = KeyFactory.create(from: keyData, type: .ecsecPrimeRandom, keyClass: .public) else {
            return nil
        }
        return key
    }
}

enum RetrieveDailyKeyError: RequestError {
    case notFound
    case unableToParse
}

extension RetrieveDailyKeyError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class RetrieveDailyKeyAsyncOperationV3: BackendAsyncDataOperation<KeyValueParameters, PublicKeyFetchResultV3, RetrieveDailyKeyError> {

    init(backendAddress: BackendAddressV3) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("keys")
            .appendingPathComponent("daily")
            .appendingPathComponent("current")

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
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
