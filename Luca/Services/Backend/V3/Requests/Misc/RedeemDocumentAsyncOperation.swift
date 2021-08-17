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
        return L10n.Test.Result.Error.title
    }

}

struct RedeemDocumentParams: Codable {
    var hash: String
    var tag: String

    /// In seconds
    var expireAt: Int
}

class RedeemDocumentAsyncOperation: BackendAsyncOperation<RedeemDocumentParams, RedeemDocumentError> {
    init(backendAddress: BackendAddress, hash: Data, tag: Data, expireAt: Date) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("tests")
            .appendingPathComponent("redeem")

        #if PRODUCTION
        let enableLog = false
        #else
        let enableLog = true
        #endif

        super.init(url: fullUrl,
                   method: .post,
                   parameters: RedeemDocumentParams(
                    hash: hash.base64EncodedString(),
                    tag: tag.base64EncodedString(),
                    expireAt: Int(expireAt.timeIntervalSince1970)
                   ),
                   enableLog: enableLog,
                   errorMappings: [
                    409: .alreadyRedeemed,
                    429: .rateLimitReached
                   ])
    }
}
