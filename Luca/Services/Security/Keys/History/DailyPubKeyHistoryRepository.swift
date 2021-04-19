import Foundation
import Security

struct DailyKeyIndex: Codable, Hashable {
    var keyId: Int
    var createdAt: Date
}

class DailyPubKeyHistoryRepository: SecKeyHistoryRepository<DailyKeyIndex> {
    init() {
        super.init(header: "MasterPubGesAmt")
    }

    var newestId: IndexType? {
        let retVal = [IndexType](self.indices)
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first

        print("Newest keyId: \(String(describing: retVal))")
        return retVal
    }

    func newest(withId: Int) -> IndexType? {
        return [IndexType](self.indices)
            .filter({ $0.keyId == withId })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
    }
}
