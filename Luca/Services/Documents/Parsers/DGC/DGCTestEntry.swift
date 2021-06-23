import Foundation
import SwiftyJSON
import SwiftDGC

private enum DGCTestResult: String {
    case detected = "260373001"
    case notDetected = "260415000"
}

struct DGCTestEntry: HCertEntry {
    var typeAddon: String { "" }

    var info: [InfoSection] {[]}

    var validityFailures: [String] {
        var fail = [String]()
        if !resultNegative {
            fail.append(l10n("hcert.err.tst.positive"))
        }
        if sampleTime > HCert.clock {
            fail.append(l10n("hcert.err.tst.future"))
        }
        return fail
    }

    enum Fields: String {
        case diseaseTargeted = "tg"
        case type = "tt"
        case sampleTime = "sc"
        case result = "tr"
        case testCenter = "tc"
        case countryCode = "co"
        case issuer = "is"
        case uvci = "ci"
    }

    init?(body: JSON) {
        guard
            let diseaseTargeted = body[Fields.diseaseTargeted.rawValue].string,
            let type = body[Fields.type.rawValue].string,
            let sampleTimeStr = body[Fields.sampleTime.rawValue].string,
            let sampleTime = Date.formatRFC3339DateTimeString(dateString: sampleTimeStr),
            let result = body[Fields.result.rawValue].string,
            let testCenter = body[Fields.testCenter.rawValue].string,
            let countryCode = body[Fields.countryCode.rawValue].string,
            let issuer = body[Fields.issuer.rawValue].string,
            let uvci = body[Fields.uvci.rawValue].string
        else {
            return nil
        }
        self.diseaseTargeted = diseaseTargeted
        self.type = type
        self.sampleTimeRaw = sampleTimeStr
        self.sampleTime = sampleTime
        self.resultNegative = (DGCTestResult(rawValue: result) == .notDetected)
        self.testCenter = testCenter
        self.countryCode = countryCode
        self.issuer = issuer
        self.uvci = uvci
    }

    var diseaseTargeted: String
    var type: String
    var sampleTimeRaw: String
    var sampleTime: Date
    var resultNegative: Bool
    var testCenter: String
    var countryCode: String
    var issuer: String
    var uvci: String
}
