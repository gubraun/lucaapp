import Foundation

enum CheckInError: RequestError {
    case invalidInput
    case notFound
    case timeMismatch
    case unableToBuildCheckInPayload(error: Error)
}

extension CheckInError {
    var errorDescription: String? {
        
        switch self  {
        case .timeMismatch:
            return "Check-in timestamp must be greater than the meeting start timestamp. Please wait a minute and try again."
        default:
            return "\(self)"
        }
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class CheckInAsyncOperationV3: BackendAsyncOperation<CheckInPayloadV3, CheckInError> {
    
    private var buildingError: CheckInError? = nil
    
    init(backendAddress: BackendAddressV3, checkInBuilder: CheckInPayloadBuilderV3,
         qrCodePayload: QRCodePayloadV3, venuePubKey: KeySource, scannerId: String) {
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("traces")
            .appendingPathComponent("checkin")
        
        var payload: CheckInPayloadV3? = nil
        do {
            payload = try checkInBuilder.build(qrCode: qrCodePayload, venuePublicKey: venuePubKey, scannerId: scannerId)
        } catch let error {
            buildingError = .unableToBuildCheckInPayload(error: error)
        }
        
        super.init(url: fullUrl,
                   method: .post,
                   parameters: payload,
                   errorMappings: [400: .invalidInput,
                                   404: .notFound,
                                   409: .timeMismatch])
    }
    
    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<CheckInError>) -> Void) -> (() -> Void) {
        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }
}
