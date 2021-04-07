import Foundation

extension Date {
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.Checkin.Slider.dateFormat
        let date = formatter.string(from: self)
        return date
    }
    
}
