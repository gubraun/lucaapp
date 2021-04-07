import Foundation

enum FetchTraceInfoError: RequestError {
    case notFound
}

extension FetchTraceInfoError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchTraceInfoRequestAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, TraceInfo, FetchTraceInfoError> {
    
    init(backendAddress: BackendAddress, traceId: TraceId) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("traces")
            .appendingPathComponent(traceId.data.toHexString())
        
        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
}
