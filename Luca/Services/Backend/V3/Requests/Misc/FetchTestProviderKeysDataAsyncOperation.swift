import Foundation

struct TestProviderKey: Codable {
    var name: String
    var fingerprint: String
    var publicKey: String
}

extension TestProviderKey: DataRepoModel {
    var identifier: Int? {
        get { Int((fingerprint.data(using: .utf8) ?? Data()).crc32) }
        set {}
    }
}

enum FetchTestProviderKeysError: RequestError {
    case notFound
}

extension FetchTestProviderKeysError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchTestProviderKeysDataAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, [TestProviderKey], FetchTestProviderKeysError> {
    init(backendAddress: BackendAddress) {

        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("testProviders")

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
}
