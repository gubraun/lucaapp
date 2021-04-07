import Foundation

struct CheckInPollPayload: Codable {
    var name: String
    var lat: Double
    var lng: Double
    var radius: Double?
}
