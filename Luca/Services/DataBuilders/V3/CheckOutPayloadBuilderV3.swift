import Foundation

struct CheckOutPayloadV3: Codable {
    var traceId: String
    var timestamp: Int
}

class CheckOutPayloadBuilderV3 {

    func build(traceId: TraceId, checkOutDate: Date) throws -> CheckOutPayloadV3 {
        let timestamp = Int(checkOutDate.lucaTimestampInteger)

        let payload = CheckOutPayloadV3(traceId: traceId.traceIdString, timestamp: timestamp)
        return payload
    }
}
