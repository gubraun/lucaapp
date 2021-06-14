import Foundation

enum DeleteUserError: RequestError {

    case badInput
    case invalidSignature
    case userNotFound
    case rateLimit
    case alreadyDeleted
    case unableToBuildPayload

}
extension DeleteUserError {

    var errorDescription: String? {
        switch self {
        case .badInput: return L10n.Error.DeleteUser.badInput
        case .invalidSignature: return L10n.Error.DeleteUser.invalidSignature
        case .userNotFound: return L10n.Error.DeleteUser.userNotFound
        case .rateLimit: return L10n.Error.DeleteUser.rateLimit
        case .alreadyDeleted: return L10n.Error.DeleteUser.alreadyDeleted
        case .unableToBuildPayload: return L10n.Error.DeleteUser.unableToBuildPayload
        }
    }

    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class DeleteUserAsyncOperationV3: BackendAsyncOperation<KeyValueParameters, DeleteUserError> {

    private var buildingError: DeleteUserError?

    init(backendAddress: BackendAddress, userId: UUID, builder: UserDataPackageBuilderV3) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("users")
            .appendingPathComponent(userId.uuidString.lowercased())

        var data = Data()
        do {
            let bytes = Data(userId.bytes)

            if let payload = "DELETE_USER".data(using: .utf8) {
                data = payload
                data.append(bytes)
                data = try builder.signature.sign(data: data)
            }
        } catch {
            buildingError = .unableToBuildPayload
        }

        let parameters: [String: String] = ["signature": data.base64EncodedString()]

        super.init(url: fullUrl,
                   method: .delete,
                   parameters: parameters,
                   errorMappings: [400: .badInput,
                                   403: .invalidSignature,
                                   404: .userNotFound,
                                   410: .alreadyDeleted,
                                   429: .rateLimit])
    }

    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<DeleteUserError>) -> Void) -> (() -> Void) {
        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }

        return super.execute(completion: completion, failure: failure)
    }

}
