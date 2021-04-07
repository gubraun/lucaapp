import Foundation

public protocol Decryption {
    func decrypt(data: Data) throws -> Data
}
