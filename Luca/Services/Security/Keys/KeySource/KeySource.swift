import Foundation

public protocol KeySource {
    func retrieveKey() -> SecKey?
}

extension KeySource {
    func retrieveKey(keyDescription: String = "key") throws -> SecKey {
        guard let key = retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve \(keyDescription)", code: 0, userInfo: nil)
        }
        return key
    }
}
