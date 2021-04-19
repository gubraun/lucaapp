import UIKit

public class QRCode: Encodable {
    var id: String
    var ts: Int

    init(userId: String) {
        id = userId
        ts = Int(Date().timeIntervalSince1970)
    }
}

public class QRCodeGenerator {

    public static func generateQRCode(data: Data) -> CIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        guard let qrCode = filter.outputImage else { return nil }
        return qrCode
    }

    public static func generateQRCode(string: String) -> CIImage? {
        generateQRCode(data: string.data(using: .utf8)!)
    }

}
