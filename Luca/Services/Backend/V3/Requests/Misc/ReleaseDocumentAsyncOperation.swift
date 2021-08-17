import Foundation

enum ReleaseDocumentError: RequestError {

    case hashNotFound

}

extension ReleaseDocumentError {

    var errorDescription: String? {
        switch self {
        case .hashNotFound: return L10n.Test.Uniqueness.Release.error
        }
    }

    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }

}

struct ReleaseDocumentParams: Codable {
    var hash: String
    var tag: String
}

/// Releases an redeemed document from backend. This document can then be redeemed on another device
class ReleaseDocumentAsyncOperation: BackendAsyncOperation<ReleaseDocumentParams, ReleaseDocumentError> {
    init(backendAddress: BackendAddress, hash: Data, tag: Data) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("tests")
            .appendingPathComponent("redeem")

        super.init(url: fullUrl,
                   method: .delete,
                   parameters: ReleaseDocumentParams(
                    hash: hash.base64EncodedString(),
                    tag: tag.base64EncodedString()
                   ),
                   errorMappings: [
                    404: .hashNotFound
                   ])
    }
}
