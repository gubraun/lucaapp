import Foundation

enum UserExistsError: RequestError {
    case notFound
}

extension UserExistsError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class UserExistsCheckRequestAsyncOperationV3: BackendAsyncOperation<KeyValueParameters, UserExistsError> {

    init(backendAddress: BackendAddress, userId: UUID) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("users")
            .appendingPathComponent(userId.uuidString.lowercased())

        super.init(url: fullUrl,
                   method: .head,
                   errorMappings: [404: .notFound])
    }
}
