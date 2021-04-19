import Foundation

enum CreateUserError: RequestError {
    case invalidInput
    case invalidSignature
    case userAlreadyExists
    case unableToBuildUserData(error: Error)
}

extension CreateUserError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class CreateUserAsyncOperationV3: MappedBackendAsyncDataOperation<UserDataPackageV3, UUID, CreateUserError> {

    private var buildingError: CreateUserError?

    init(backendAddress: BackendAddressV3, builder: UserDataPackageBuilderV3, data: UserRegistrationData) {

        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("users")

        var payload: UserDataPackageV3?
        do {
            payload = try builder.build(userData: data)
        } catch let error {
            buildingError = .unableToBuildUserData(error: error)
        }

        super.init(url: fullUrl,
                   method: .post,
                   parameters: payload,
                   errorMappings: [400: .invalidInput,
                                   403: .invalidSignature,
                                   409: .userAlreadyExists])
    }

    override func execute(completion: @escaping (UUID) -> Void, failure: @escaping (BackendError<CreateUserError>) -> Void) -> (() -> Void) {

        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }

    override func map(dict: [String: Any]) throws -> UUID {

        if let userIdString = dict["userId"] as? String,
           let userId = UUID(uuidString: userIdString) {

            return userId

        } else {
            throw NetworkError.invalidResponsePayload
        }
    }

}
