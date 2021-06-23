import Foundation

extension Date {

    /// Format "dd.MM.yyyy HH.mm"
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Checkin.Slider.dateFormat
        let date = formatter.string(from: self)
        return date
    }

    /// Format "dd.MM.yyyy"
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Test.Result.dateFormat
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

    var durationSinceDate: String {

        if let hour = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour,
           let minute = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute {
            if minute < 60 {
                return L10n.Test.Result.Duration.minutes(minute)
            } else if hour == 1 {
                return L10n.Test.Result.Duration.hour
            }
            return L10n.Test.Result.Duration.hours(hour)
        }

        return "Time error"
    }

    /// Format string with ubirch date format (e.g. 19640812 = 12.Aug 1964)
    /// - Parameter dateString: ubirch date formated string
    /// - Returns: Date
    static func formatUbirchDateString(dateString: String) -> Date? {
        return Date.formatDateString(dateString: dateString, format: "yyyyMMdd")
    }

    /// Format string with ubirch date and time format (e.g. 202007011030 = 01.July 2020 10:30am)
    /// - Parameter dateString: ubirch date and time formated string
    /// - Returns: Date
    static func formatUbirchDateTimeString(dateString: String) -> Date? {
        return Date.formatDateString(dateString: dateString, format: "yyyyMMddHHmm")
    }

    /// Format string with DGC date format (e.g. 19640812 = 12.Aug 1964)
    /// - Parameter dateString: ubirch date formated string
    /// - Returns: Date
    static func formatDGCDateString(dateString: String) -> Date? {
        return Date.formatDateString(dateString: dateString, format: "yyyy-MM-dd")
    }

    static func formatDateString(dateString: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: dateString)
    }

    /// Format RFC3339 date time string
    /// based on SwiftDGC implementation
    /// - Parameter dateString: string in RFC3339 format
    static func formatRFC3339DateTimeString(dateString: String) -> Date? {
      var str = dateString
      let rfc3339DateTimeFormatter = DateFormatter()

      if (try? NSRegularExpression(
        pattern: "\\.[0-9]{6}Z?$", options: []
      ).matches(
        in: str, options: [], range: NSRange(
          str.startIndex..<str.endIndex,
          in: str
        )
      ))?.isEmpty == false {
        str = str.trimmingCharacters(in: ["Z"])
        str = String(str.prefix(str.count - 3)) + "Z"
      }

      for fmt in [
        "yyyy-MM-dd'T'HH:mm:ssZZZZZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
        "yyyy-MM-dd't'HH:mm:ss'z'", "yyyy-MM-dd't'HH:mm:ss.SSS'z'"
      ] {
        rfc3339DateTimeFormatter.dateFormat = fmt
        if let date = rfc3339DateTimeFormatter.date(from: str) {
          return date
        }
      }
      return nil
    }
}
