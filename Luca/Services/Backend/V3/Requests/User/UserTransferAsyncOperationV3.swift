import Foundation

enum UserTransferError: RequestError {
    case invalidInput
    case invalidSignature
    case notFound
    case unableToBuildUserTransferData(error: Error)
}

extension UserTransferError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class UserTransferAsyncOperationV3: MappedBackendAsyncDataOperation<UserTransferDataV3, String, UserTransferError> {

    private var buildingError: UserTransferError?

    init(backendAddress: BackendAddressV3, userTransferBuilder: UserTransferBuilderV3, userId: UUID) {
        var payload: UserTransferDataV3?
        do {
            payload = try userTransferBuilder.build(userId: userId)
        } catch let error {
            buildingError = .unableToBuildUserTransferData(error: error)
        }

        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("userTransfers")

        super.init(url: fullUrl,
                   method: .post,
                   parameters: payload,
                   errorMappings: [400: .invalidInput,
                                   403: .invalidSignature,
                                   404: .notFound])
    }

    override func execute(completion: @escaping (String) -> Void, failure: @escaping (BackendError<UserTransferError>) -> Void) -> (() -> Void) {
        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }

    override func map(dict: [String: Any]) throws -> String {
        if let tan = dict["tan"] as? String {
            return tan
        }
        throw NetworkError.invalidResponsePayload
    }
}
