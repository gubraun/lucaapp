import Foundation

enum FetchScannerError: RequestError {
    case notFound
}

extension FetchScannerError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchScannerAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, ScannerInfo, FetchScannerError> {

    init(backendAddress: BackendAddress, scannerId: String) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("scanners")
            .appendingPathComponent(scannerId.lowercased())

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
}
