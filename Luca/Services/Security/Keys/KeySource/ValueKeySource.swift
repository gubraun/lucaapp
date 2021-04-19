import Foundation

class ValueKeySource: KeySource {
    private let key: SecKey

    init(key: SecKey) {
        self.key = key
    }

    func retrieveKey() -> SecKey? {
        return key
    }
}
