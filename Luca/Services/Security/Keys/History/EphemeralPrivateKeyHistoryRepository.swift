import Foundation

class EphemeralPrivateKeyHistoryRepository: SecKeyHistoryRepository<Int> {
    init() {
        super.init(header: "EphemeralPrivate")
    }
}
