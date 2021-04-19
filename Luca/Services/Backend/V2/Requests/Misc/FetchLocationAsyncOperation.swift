import Foundation

enum FetchLocationError: RequestError {
    case notFound
}

extension FetchLocationError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchLocationAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, Location, FetchLocationError> {

    init(backendAddress: BackendAddress, locationId: UUID) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("locations")
            .appendingPathComponent(locationId.uuidString.lowercased())

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
}
