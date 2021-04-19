import Foundation

enum TimeUnit {
    case day(amount: Double)
    case hour(amount: Double)
    case minute(amount: Double)

    var timeInterval: TimeInterval {
        switch self {
        case .day(let amount):
            return amount * 60 * 60 * 24
        case .hour(let amount):
            return amount * 60 * 60
        case .minute(let amount):
            return amount * 60
        }
    }
}
