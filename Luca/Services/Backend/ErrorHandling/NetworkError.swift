import Foundation

enum NetworkError: LocalizedTitledError {

    case noInternet
    case timeout
    case invalidResponse
    case invalidResponsePayload
    case invalidRequest
    case badGateway

    /// Used when parser couldn't find required key
    case keyNotFound(key: String)

    case certificateValidationFailed

    case unknown(error: Error)
}

extension NetworkError {

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return L10n.General.Failure.NoInternet.message
        case .certificateValidationFailed:
            return L10n.General.Failure.InvalidCertificate.message
        case .badGateway:
            return L10n.Error.Network.badGateway
        default:
            return "\(self)"
        }
    }

    var localizedTitle: String {
        switch self {
        case .certificateValidationFailed:
            return L10n.General.Failure.InvalidCertificate.title
        default:
            return L10n.Navigation.Basic.error
        }
    }
}
