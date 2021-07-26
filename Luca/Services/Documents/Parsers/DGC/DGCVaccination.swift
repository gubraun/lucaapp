import UIKit

enum DGCVaccinationType: String, Codable {

    case cormirnaty = "EU/1/20/1528"
    case janssen = "EU/1/20/1525"
    case moderna = "EU/1/20/1507"
    case vaxzevria = "EU/1/21/1529"
    case sputnikV = "Sputnik-V"

    var category: String {
        switch self {
        case .cormirnaty: return L10n.Vaccine.Result.cormirnaty
        case .janssen: return L10n.Vaccine.Result.janssen
        case .moderna: return L10n.Vaccine.Result.moderna
        case .vaxzevria: return L10n.Vaccine.Result.vaxzevria
        case .sputnikV: return L10n.Vaccine.Result.sputnikV
        }
    }
}

struct DGCVaccination: Vaccination & DocumentCellViewModel {

    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var vaccineType: String
    var doseNumber: Int
    var dosesTotalNumber: Int
    var date: Date
    var originalCode: String
    var issuer: String
    var laboratory: String { issuer }

    init(cert: DGCCert, vaccine: DGCVaccinationEntry, originalCode: String) {
        self.firstName = cert.firstName
        self.lastName = cert.lastName
        self.dateOfBirth = cert.dateOfBirth
        self.date = vaccine.date
        self.vaccineType = DGCVaccinationType(rawValue: vaccine.medicalProduct)!.category
        self.doseNumber = vaccine.doseNumber
        self.dosesTotalNumber = vaccine.dosesTotal
        self.issuer = vaccine.issuer
        self.originalCode = originalCode
    }

    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseAppFullname = formatUser(withFirstName: firstName, lastName: lastName)
        let uppercaseTestFullname = formatUser(withFirstName: self.firstName, lastName: self.lastName)
        return uppercaseAppFullname == uppercaseTestFullname
    }

    private func formatUser(withFirstName firstName: String, lastName: String) -> String {
        return (firstName + lastName).uppercased()
            .removeOccurences(of: ["DR.", "PROF."])
            .removeNonUppercase()
            .removeWhitespaces()
    }

    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaVaccineTableViewCell", for: indexPath) as! CoronaVaccineTableViewCell
        cell.vaccination = self
        cell.delegate = delegate

        return cell
    }
}
