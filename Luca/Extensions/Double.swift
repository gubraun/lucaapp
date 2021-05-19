import UIKit

public extension Double {

    var hoursTimeUnit: Int {
        return Int(self) / 3600
    }

    var minutesTimeUnit: Int {
        return Int(self) / 60 % 60
    }

    var secondsTimeUnit: Int {
        return Int(self) % 60
    }

    /// Returns a string containing time with the format of HH:mm:ss
    var formattedTimeString: String {
        return String(format: "%02i:%02i:%02i", self.hoursTimeUnit, self.minutesTimeUnit, self.secondsTimeUnit)
    }

    var formattedExpiryTimeMinutes: String {
        return String(format: "%i %@", self.minutesTimeUnit, L10n.Test.Expiry.minutes)
    }

    var formattedExpiryTimeHours: String {
        return String(format: "%i %@", self.hoursTimeUnit, L10n.Test.Expiry.hours)
    }

}
