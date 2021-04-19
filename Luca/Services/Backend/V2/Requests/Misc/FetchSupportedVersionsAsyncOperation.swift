import Foundation

struct SupportedVersions: Codable {
    var minimumVersion: Int
}

enum FetchSupportedVersionError: RequestError {
    case notFound
}

extension FetchSupportedVersionError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchSupportedVersionsAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, SupportedVersions, FetchSupportedVersionError> {
    init(backendAddress: BackendAddress) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("versions")
            .appendingPathComponent("apps")
            .appendingPathComponent("ios")

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
}
