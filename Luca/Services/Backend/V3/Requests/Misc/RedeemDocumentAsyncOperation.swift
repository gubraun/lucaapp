import Foundation

enum RedeemDocumentError: RequestError {

    case alreadyRedeemed
    case rateLimitReached

}

extension RedeemDocumentError {

    var errorDescription: String? {
        switch self {
        case .alreadyRedeemed: return L10n.Test.Uniqueness.Redeemed.error
        case .rateLimitReached: return L10n.Test.Uniqueness.Rate.Limit.error
        }
    }

    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }

}

class RedeemDocumentAsyncOperation: BackendAsyncOperation<KeyValueParameters, RedeemDocumentError> {
    init(backendAddress: BackendAddress, hash: Data, tag: Data) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("tests")
            .appendingPathComponent("redeem")

        let parameters: [String: String] = [
            "hash": hash.base64EncodedString(),
            "tag": tag.base64EncodedString()
        ]

        super.init(url: fullUrl,
                   method: .post,
                   parameters: parameters,
                   errorMappings: [
                    409: .alreadyRedeemed,
                    429: .rateLimitReached
                   ])
    }
}
