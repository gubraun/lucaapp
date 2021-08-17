import Foundation

enum QRType {

    case checkin
    case document
    case url

}

enum QRProcessingError: LocalizedTitledError {

    case parsingFailed

}

extension QRProcessingError {

    var localizedTitle: String {
        switch self {
        case .parsingFailed: return L10n.Camera.Warning.Incompatible.title
        }
    }

    var errorDescription: String? {
        switch self {
        case .parsingFailed: return L10n.Camera.Warning.Incompatible.description
        }
    }

}
