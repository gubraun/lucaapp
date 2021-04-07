import Foundation

/// This protocol is used the retrieve raw keys. It is used for types not officially supported by the Security library in iOS
public protocol RawKeySource {
    func retrieveKey() -> Data?
}

extension RawKeySource {
    func retrieveKey(keyDescription: String = "key") throws -> Data {
        guard let key = retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve data \(keyDescription)", code: 0, userInfo: nil)
        }
        return key
    }
}
