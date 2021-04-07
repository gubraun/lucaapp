import Foundation

enum DeletePrivateMeetingError: RequestError {
    case invalidInput
    case notFound
}

extension DeletePrivateMeetingError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class DeletePrivateMeetingAsyncOperation: BackendAsyncOperation<KeyValueParameters, DeletePrivateMeetingError> {
    
    init(backendAddress: BackendAddressV3, accessId: String) {
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("locations")
            .appendingPathComponent(accessId.lowercased())
        
        super.init(url: fullUrl,
                   method: .delete,
                   errorMappings: [400: .invalidInput,
                                   404: .notFound])
    }
}
