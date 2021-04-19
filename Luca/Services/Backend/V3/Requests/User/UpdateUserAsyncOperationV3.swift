import UIKit

enum UpdateUserError: RequestError {
    case invalidInput
    case invalidSignature
    case notFound
    case unableToBuildUserData(error: Error)
}

extension UpdateUserError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class UpdateUserAsyncOperationV3: BackendAsyncOperation<UserDataPackageV3, UpdateUserError> {

    private var buildingError: UpdateUserError?

    init(backendAddress: BackendAddressV3, builder: UserDataPackageBuilderV3, data: UserRegistrationData, userId: UUID) {

        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("users")
            .appendingPathComponent(userId.uuidString.lowercased())

        var payload: UserDataPackageV3?
        do {
            payload = try builder.build(userData: data, withPublicKey: false)
        } catch let error {
            buildingError = .unableToBuildUserData(error: error)
        }

        super.init(url: fullUrl,
                   method: .patch,
                   parameters: payload,
                   errorMappings: [400: .invalidInput,
                                   403: .invalidSignature,
                                   404: .notFound])
    }

    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<UpdateUserError>) -> Void) -> (() -> Void) {

        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }

}
