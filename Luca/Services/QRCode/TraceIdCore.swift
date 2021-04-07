import Foundation

struct TraceIdCore: Codable {
    
    /// Date this trace has been created. Used also as index for ephemeral key history repositories
    var date: Date
    
    /// Daily key ID this trace id is associated with
    var keyId: UInt8
}

extension TraceIdCore: DataRepoModel, Hashable {
    var identifier: Int? {
        get {
            var checksum = Data()
            
            checksum.append(date.timeIntervalSince1970.data)
            checksum.append(keyId.data)
            
            return Int(checksum.crc32)
        }
        set { }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(keyId)
    }
}

extension Date {
    
    /// Correctly parsed data for V2 Crypto
    var lucaTimestampInteger: UInt32 {
        let integer = UInt32(timeIntervalSince1970)
        return integer - (integer % 60)
    }
    
    /// Correctly parsed data for V2 Crypto
    var lucaTimestamp: Data {
        let integer = lucaTimestampInteger
        let data = withUnsafeBytes(of: integer, { Data($0) })
        return data
    }
}

extension TraceIdCore: Equatable {
}
