import Foundation

extension Date {

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Checkin.Slider.dateFormat
        let date = formatter.string(from: self)
        return date
    }

    var accessibilityDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        let date = formatter.string(from: self)
        return date
    }

    /// Format string with ubirch date format (e.g. 19640812 = 12.Aug 1964)
    /// - Parameter dateString: ubirch date formated string
    /// - Returns: Date
    static func formatUbirchDateString(dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: dateString)
    }

    /// Format string with ubirch date and time format (e.g. 202007011030 = 01.July 2020 10:30am)
    /// - Parameter dateString: ubirch date and time formated string
    /// - Returns: Date
    static func formatUbirchDateTimeString(dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        return dateFormatter.date(from: dateString)
    }
}
