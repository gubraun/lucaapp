import Foundation
import SwiftyJSON
import SwiftDGC

struct DGCRecoveryEntry: HCertEntry {
    var typeAddon: String { "" }

    var info: [InfoSection] {
        []
    }

    var validityFailures: [String] {
        var fail = [String]()
        if validFrom > HCert.clock {
            fail.append(l10n("hcert.err.rec.future"))
        }
        if validUntil < HCert.clock {
            fail.append(l10n("hcert.err.rec.past"))
        }
        return fail
    }

    enum Fields: String {
        case diseaseTargeted = "tg"
        case firstPositiveDate = "fr"
        case countryCode = "co"
        case issuer = "is"
        case validFrom = "df"
        case validUntil = "du"
        case uvci = "ci"
    }

    init?(body: JSON) {
        guard
            let diseaseTargeted = body[Fields.diseaseTargeted.rawValue].string,
            let firstPositiveDate = body[Fields.firstPositiveDate.rawValue].string,
            let countryCode = body[Fields.countryCode.rawValue].string,
            let issuer = body[Fields.issuer.rawValue].string,
            let validFromStr = body[Fields.validFrom.rawValue].string,
            let validUntilStr = body[Fields.validUntil.rawValue].string,
            let validFrom = Date.formatDGCDateString(dateString: validFromStr),
            let validUntil = Date.formatDGCDateString(dateString: validUntilStr),
            let uvci = body[Fields.uvci.rawValue].string
        else {
            return nil
        }
        self.diseaseTargeted = diseaseTargeted
        self.firstPositiveDate = firstPositiveDate
        self.countryCode = countryCode
        self.issuer = issuer
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.uvci = uvci
    }

    var diseaseTargeted: String
    var firstPositiveDate: String
    var countryCode: String
    var issuer: String
    var validFrom: Date
    var validUntil: Date
    var uvci: String
}
