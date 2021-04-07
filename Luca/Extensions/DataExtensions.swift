import Foundation

extension Numeric {
    
    /// Returns raw data bytes
    var data: Data {
        var retVal = Data()
        var selfCopy = self
        Swift.withUnsafeMutableBytes(of: &selfCopy) { retVal.append(contentsOf: $0) }
        return retVal
    }
}

extension Data {
    
    /// CRC32 loaded as Int32
    var crc32: Int32 {
        let crc = self.crc32()
        return crc.withUnsafeBytes({ $0.load(as: Int32.self) })
    }
}

