import Foundation

struct HealthDepartment: Codable, Equatable, Hashable {
    var departmentId: String
    var name: String
    var publicHDEKP: String
    var publicHDSKP: String
}

extension HealthDepartment: DataRepoModel {

    var identifier: Int? {
        get {
            let checksum = departmentId.data(using: .utf8)!.crc32

            return Int(checksum)
        }
        set { }
    }
}

extension HealthDepartment {
    var parsedDepartmentId: UUID? {
        UUID(uuidString: departmentId)
    }
}

struct Location: Codable {
    var locationId: String
    var publicKey: String
    @available(*, deprecated, message: "Use locationName or groupName instead")
    var name: String?
    var groupName: String?
    var locationName: String?
    var firstName: String?
    var lastName: String?
    var phone: String?
    var streetName: String?
    var streetNr: String?
    var zipCode: String?
    var city: String?
    var state: String?
    var lat: Double?
    var lng: Double?
    var radius: Double
    var startsAt: Int?
    var endsAt: Int?
}
extension Location: DataRepoModel, Hashable {

    var identifier: Int? {
        get {
            let checksum = locationId.data(using: .utf8)!.crc32

            return Int(checksum)
        }
        set { }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(locationId)
    }
}

extension Location {
    var startsAtDate: Date? {
        if let starts = startsAt {
            return Date(timeIntervalSince1970: Double(starts))
        }
        return nil
    }
    var endsAtDate: Date? {
        if let ends = endsAt {
            return Date(timeIntervalSince1970: Double(ends))
        }
        return nil
    }
}

extension Location {
    var geoLocationRequired: Bool {
        return radius > 0
    }
}

extension Location {
    var formattedName: String? {
        switch (groupName, locationName) {
        case (.some(let groupName), nil):
            return groupName
        case (.some(let groupName), .some(let locationName)):
            return groupName + " - " + locationName
        case (nil, .some(let locationName)):
            return locationName
        default:
            return name
        }
    }
}

struct UserInfoRetrieval: Codable {
    var retrievedAt: Int
    var department: String
    var employee: String
}

struct TraceInfo: Codable {
    var traceId: String
    var checkin: Int
    var checkout: Int?
    var locationId: String
    var createdAt: Int?
}

extension TraceInfo: DataRepoModel {

    var identifier: Int? {
        get {
            var checksum = Data()
            checksum = traceId.data(using: .utf8)!
            checksum.append(checkin.data)
            return Int(checksum.crc32)
        }
        set { }
    }
}

extension TraceInfo {
    var parsedLocationId: UUID? {
        UUID(uuidString: locationId)
    }
    var checkInDate: Date {
        Date(timeIntervalSince1970: Double(checkin))
    }
    var checkOutDate: Date? {
        if let checkout = checkout {
            return Date(timeIntervalSince1970: Double(checkout))
        }
        return nil
    }
    var createdAtDate: Date? {
        if let createdAt = createdAt {
            return Date(timeIntervalSince1970: Double(createdAt))
        }
        return nil
    }
    var isCheckedIn: Bool {
        checkout == nil || Int(Date().timeIntervalSince1970) < checkout!
    }
    var traceIdData: TraceId? {
        if let data = Data(base64Encoded: traceId) {
            return TraceId(data: data, checkIn: checkInDate)
        }
        return nil
    }
}

struct ScannerInfo: Codable {
    var scannerId: String
    var locationId: String
    var publicKey: String
    var name: String?
    var tableCount: Int?
}
