import Foundation

class FetchTraceInfosRequestAsyncOperation: BackendAsyncDataOperation<[String: [String]], [TraceInfo], FetchTraceInfoError> {

    init(backendAddress: BackendAddress, traceIds: [TraceId]) {
        var traceIdStrings: [String] = []
        for traceId in traceIds {
            traceIdStrings.append(traceId.traceIdString)
        }

        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("traces")
            .appendingPathComponent("bulk")

        let parameters: [String: [String]] = ["traceIds": traceIdStrings]

        super.init(url: fullUrl,
                   method: .post,
                   parameters: parameters,
                   errorMappings: [404: .notFound])
    }
}
