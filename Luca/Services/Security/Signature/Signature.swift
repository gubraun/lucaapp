import Foundation

protocol Signature {
    func sign(data: Data) throws -> Data
    func verify(data: Data, signature: Data) throws -> Bool
}
