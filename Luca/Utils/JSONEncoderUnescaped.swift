import Foundation

class JSONEncoderUnescaped: JSONEncoder {
    override func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let data = try super.encode(value)
        return try data.unescaped()
    }
}
