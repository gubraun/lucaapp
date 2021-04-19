import Foundation

class ValueRawKeySource: RawKeySource {
    private let key: Data

    init(key: Data) {
        self.key = key
    }

    func retrieveKey() -> Data? {
        return key
    }
}
