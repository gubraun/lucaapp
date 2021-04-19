import Foundation

class DailyDataKeyRepository: KeyHistoryRepository<Date, Data> {

    private var underlying: RawKeyHistoryRepository<Int>

    override var factory: ((Date) throws -> Data)? {
        didSet {
            if let factory = self.factory {
                underlying.factory = { intIndex in try factory(Date(timeIntervalSince1970: Double(intIndex)))}
            } else {
                underlying.factory = nil
            }
        }
    }

    override var indices: Set<Date> {
        Set(underlying.indices.map { Date(timeIntervalSince1970: Double($0)) })
    }

    override init(header: String) {
        underlying = RawKeyHistoryRepository(header: header)
        super.init(header: header)
    }

    override func store(key: Data, index: Date) throws {
        try underlying.store(key: key, index: toDailyDate(date: index))
    }
    override func restore(index: Date, enableFactoryIfAvailable: Bool = true) throws -> Data {
        return try underlying.restore(index: toDailyDate(date: index), enableFactoryIfAvailable: enableFactoryIfAvailable)
    }
    override func remove(index: Date) {
        underlying.remove(index: toDailyDate(date: index))
    }
    override func removeAll() {
        underlying.removeAll()
    }

    private func toDailyDate(date: Date) -> Int {
        Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970)
    }
}
