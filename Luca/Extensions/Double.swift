import UIKit

public extension Double {

    /// Returns a string containing time with the format of HH:mm:ss
    var formattedTimeString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }

}
