import Foundation

enum UploadAdditionalDataError: RequestError {
    case notFound
    case invalidInput
    case failedToBuildAdditionalDataPayload(error: Error)
}

extension UploadAdditionalDataError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class UploadAdditionalDataRequestAsyncOperationV3<T>: BackendAsyncOperation<TraceIdAdditionalDataPayloadV3, UploadAdditionalDataError> where T: Encodable{
    
    var buildingError: UploadAdditionalDataError? = nil
    
    init(backendAddress: BackendAddressV3, additionalDataBuilder: TraceIdAdditionalDataBuilderV3,
         traceId: TraceId, scannerId: String, venuePubKey: KeySource, additionalData: T) {
        
        var checkoutPayload: TraceIdAdditionalDataPayloadV3? = nil
        do {
            checkoutPayload = try additionalDataBuilder
                .build(traceId: traceId, scannerId: scannerId, venuePubKey: venuePubKey, additionalData: additionalData)
        } catch let error {
            buildingError = .failedToBuildAdditionalDataPayload(error: error)
        }
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("traces")
            .appendingPathComponent("additionalData")
        
        super.init(url: fullUrl,
                   method: .post,
                   parameters: checkoutPayload,
                   errorMappings: [400: .invalidInput,
                                   404: .notFound])
    }
    
    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<UploadAdditionalDataError>) -> Void) -> (() -> Void) {
        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }
}

