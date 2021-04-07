import Foundation

class EphemeralPublicKeyHistoryRepository: SecKeyHistoryRepository<Int> {
    init() {
        super.init(header: "EphemeralPublic")
    }
}
