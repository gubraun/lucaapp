import Foundation

enum CheckOutError: RequestError {
    case invalidInput
    case invalidSignature
    case notFound
    case checkInTimeLargerThanCheckOutTime
    case failedToBuildCheckOutPayload(error: Error)
}

extension CheckOutError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class CheckOutAsyncOperationV3: BackendAsyncOperation<CheckOutPayloadV3, CheckOutError> {
    
    var buildingError: CheckOutError? = nil
    
    init(backendAddress: BackendAddressV3, checkOutBuilder: CheckOutPayloadBuilderV3, traceId: TraceId, timestamp: Date) {
        var checkoutPayload: CheckOutPayloadV3? = nil
        do {
            checkoutPayload = try checkOutBuilder.build(traceId: traceId, checkOutDate: timestamp)
        } catch let error {
            buildingError = .failedToBuildCheckOutPayload(error: error)
        }
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("traces")
            .appendingPathComponent("checkout")
        
        super.init(url: fullUrl,
                   method: .post,
                   parameters: checkoutPayload,
                   errorMappings: [400: .invalidInput,
                                   403: .invalidSignature,
                                   404: .notFound,
                                   409: .checkInTimeLargerThanCheckOutTime])
    }
    
    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<CheckOutError>) -> Void) -> (() -> Void) {
        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }
}

