import Foundation

class LocationPrivateKeyHistoryRepository: SecKeyHistoryRepository<Int> {
    init() {
        super.init(header: "LocationPrivate")
    }
}
