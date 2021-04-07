import Foundation

struct PrivateMeetingQRCodeV3AdditionalData: Codable {
    var fn: String
    var ln: String
}

struct PrivateMeetingQRCodeV3 {
    var additionalData: PrivateMeetingQRCodeV3AdditionalData
    var scannerId: String
    var host: URL
}

extension PrivateMeetingQRCodeV3 {
    var generatedUrl: String? {
        guard let payload = try? JSONEncoderUnescaped().encode(additionalData).base64urlEncodedString() else {
            return nil
        }
        let url = host.appendingPathComponent("webapp")
            .appendingPathComponent("meeting")
            .appendingPathComponent("\(scannerId)")
        return "\(url.absoluteString)#\(payload)"
    }
}

class PrivateMeetingQRCodeBuilderV3 {
    private let backendAddress: BackendAddressV3
    private let preferences: LucaPreferences
    
    init(backendAddress: BackendAddressV3, preferences: LucaPreferences) {
        self.backendAddress = backendAddress
        self.preferences = preferences
    }
    
    func build(scannerId: String) throws -> PrivateMeetingQRCodeV3 {
        guard let firstName = preferences.userRegistrationData?.firstName,
              let lastName = preferences.userRegistrationData?.lastName else {
            throw NSError(domain: "Couldn't obtain user name from data", code: 0, userInfo: nil)
        }
        let additionalData = PrivateMeetingQRCodeV3AdditionalData(fn: firstName, ln: lastName)
        return PrivateMeetingQRCodeV3(additionalData: additionalData, scannerId: scannerId, host: backendAddress.host)
    }
}
