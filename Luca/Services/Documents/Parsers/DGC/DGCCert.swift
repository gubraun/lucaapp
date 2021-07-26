import Foundation
import SwiftDGC
import SwiftyJSON

private enum DGCAttributeKey: String {
    case firstName
    case lastName
    case firstNameStandardized
    case lastNameStandardized
    case gender
    case dateOfBirth
    case testStatements
    case vaccineStatements
    case recoveryStatements
}

struct DGCCert {
    let hCert: HCert

    fileprivate let attributeKeys: [DGCAttributeKey: [String]] = [
        .firstName: ["nam", "gn"],
        .lastName: ["nam", "fn"],
        .firstNameStandardized: ["nam", "gnt"],
        .lastNameStandardized: ["nam", "fnt"],
        .dateOfBirth: ["dob"],
        .testStatements: ["t"],
        .vaccineStatements: ["v"],
        .recoveryStatements: ["r"]
    ]

    var firstName: String {
        return get(.firstName).string ?? "MissingFirstName"
    }

    var lastName: String {
        return get(.lastName).string ?? "MissingFirstName"
    }

    var dateOfBirth: Date {
        if let dateOfBirthString = get(.dateOfBirth).string,
           let dateOfBirthDate = Date.formatDGCDateString(dateString: dateOfBirthString) {
            return dateOfBirthDate
        }
        return Date()
    }

    var testStatements: [DGCTestEntry] {
        return get(.testStatements)
            .array?
            .compactMap {
                DGCTestEntry(body: $0)
            } ?? []
    }

    var vaccineStatements: [DGCVaccinationEntry] {
        return get(.vaccineStatements)
            .array?
            .compactMap {
                DGCVaccinationEntry(body: $0)
            } ?? []
    }
    var recoveryStatements: [DGCRecoveryEntry] {
        return get(.recoveryStatements)
            .array?
            .compactMap {
                DGCRecoveryEntry(body: $0)
            } ?? []
    }

    init(hCert: HCert) {
        self.hCert = hCert
    }

    fileprivate func get(_ attribute: DGCAttributeKey) -> JSON {
        var object = hCert.body
        for key in attributeKeys[attribute] ?? [] {
            object = object[key]
        }
        return object
    }

}
