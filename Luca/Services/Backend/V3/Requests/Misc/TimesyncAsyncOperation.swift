import Foundation

 enum TimesyncError: RequestError {}

 extension TimesyncError {
    var localizedTitle: String {
        return ""
    }
 }

struct Timesync: Codable, Equatable {
    var unix: Int
}

class FetchTimesyncAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, Timesync, TimesyncError> {
    init(backendAddress: BackendAddress) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("timesync")

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [:])
    }
}
