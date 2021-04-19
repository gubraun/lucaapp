import Foundation

enum FetchAccessedTracesError {
    case notFound
}

extension FetchAccessedTracesError: RequestError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

struct AccessedTrace: Codable, Equatable {
    var healthDepartment: HealthDepartment
    var hashedTraceIds: [String]
}

extension AccessedTrace {
    func intersection(with dict: [String: TraceInfo]) -> [TraceInfo] {

        return dict
            .filter { entry in hashedTraceIds.contains(entry.0) }
            .map { $0.value }
    }
}

class FetchAccessedTracesAsyncDataOperation: BackendAsyncDataOperation<KeyValueParameters, [AccessedTrace], FetchAccessedTracesError> {

    init(backendAddress: BackendAddress) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("notifications")
            .appendingPathComponent("traces")

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [:])
    }
}
