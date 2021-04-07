import Foundation

enum FetchLocationGuestsError: RequestError {
    case invalidInput
}

extension FetchLocationGuestsError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchGuestListAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, [PrivateMeetingGuest], FetchLocationGuestsError> {
    init(backendAddress: BackendAddressV3, accessId: String) {
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("locations")
            .appendingPathComponent("traces")
            .appendingPathComponent(accessId.lowercased())
        
        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [400: .invalidInput])
    }
}
