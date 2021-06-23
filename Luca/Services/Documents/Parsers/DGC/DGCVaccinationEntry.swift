import Foundation
import SwiftyJSON
import SwiftDGC

struct DGCVaccinationEntry: HCertEntry {
    var typeAddon: String {
        let format = l10n("vaccine.x-of-x")
        return .localizedStringWithFormat(format, doseNumber, dosesTotal)
    }

    var info: [InfoSection] {
        []
    }

    var validityFailures: [String] {
        var fail = [String]()
        if date > HCert.clock {
            fail.append(l10n("hcert.err.vac.future"))
        }
        return fail
    }

    enum Fields: String {
        case diseaseTargeted = "tg"
        case vaccineOrProphylaxis = "vp"
        case medicalProduct = "mp"
        case manufacturer = "ma"
        case doseNumber = "dn"
        case dosesTotal = "sd"
        case date = "dt"
        case countryCode = "co"
        case issuer = "is"
        case uvci = "ci"
    }

    init?(body: JSON) {
        guard
            let diseaseTargeted = body[Fields.diseaseTargeted.rawValue].string,
            let vaccineOrProphylaxis = body[Fields.vaccineOrProphylaxis.rawValue].string,
            let medicalProduct = body[Fields.medicalProduct.rawValue].string,
            let manufacturer = body[Fields.manufacturer.rawValue].string,
            let country = body[Fields.countryCode.rawValue].string,
            let issuer = body[Fields.issuer.rawValue].string,
            let uvci = body[Fields.uvci.rawValue].string,
            let doseNumber = body[Fields.doseNumber.rawValue].int,
            let dosesTotal = body[Fields.dosesTotal.rawValue].int,
            let dateStr = body[Fields.date.rawValue].string,
            let date = Date.formatDGCDateString(dateString: dateStr)
        else {
            return nil
        }
        self.diseaseTargeted = diseaseTargeted
        self.vaccineOrProphylaxis = vaccineOrProphylaxis
        self.medicalProduct = medicalProduct
        self.manufacturer = manufacturer
        self.countryCode = country
        self.issuer = issuer
        self.uvci = uvci
        self.doseNumber = doseNumber
        self.dosesTotal = dosesTotal
        self.date = date
    }

    var diseaseTargeted: String
    var vaccineOrProphylaxis: String
    var medicalProduct: String
    var manufacturer: String
    var countryCode: String
    var issuer: String
    var uvci: String
    var doseNumber: Int
    var dosesTotal: Int
    var date: Date
}
