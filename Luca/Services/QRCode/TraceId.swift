import Foundation

struct TraceId: Codable, Equatable {
    private(set) var data: Data
    private(set) var checkIn: Date
    init?(data: Data, checkIn: Date) {
        if data.count == 16 {
            self.data = data
            self.checkIn = checkIn
        } else { return nil }
    }
}

extension TraceId {
    var traceIdString: String {
        data.base64EncodedString()
    }
}
