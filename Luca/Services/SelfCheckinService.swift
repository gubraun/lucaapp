import Foundation
import RxSwift
import base64url

struct SelfCheckInPayload {
    var scannerId: String
    var additionalData: String
}

private struct SelfCheckInPayloadData {
    let scannerId: String
    let additionalData: Data
}

class SelfCheckin {
    var url: URL
    init(url: URL) {
        self.url = url
    }

    fileprivate static func payloadData(from urlString: String) -> SelfCheckInPayloadData? {
        guard let parameters = urlString.split(separator: "/").last else {
            return nil
        }

        let splitted = parameters.split(separator: "#")
        guard splitted.count == 2,
              let scannerId = splitted.first,
              let additionalData = splitted.last,
              scannerId != additionalData else {
            return nil
        }

        guard let data = Data(base64urlEncoded: String(additionalData)) else {
            return nil
        }

        return SelfCheckInPayloadData(scannerId: String(scannerId), additionalData: data)
    }
}

class PrivateMeetingSelfCheckin: SelfCheckin {
    var additionalData: PrivateMeetingQRCodeV3AdditionalData
    var scannerId: String
    init?(urlToParse: URL) {

        guard let components = NSURLComponents(url: urlToParse, resolvingAgainstBaseURL: true),
              let componentArray = components.path?.split(separator: "/"),
              componentArray.count == 3,
              componentArray.first == "webapp",
              componentArray[1] == "meeting" else {
            return nil
        }

        guard let payloadData = SelfCheckin.payloadData(from: urlToParse.absoluteString) else { return nil }

        guard let parsedData = try? JSONDecoder().decode(PrivateMeetingQRCodeV3AdditionalData.self, from: payloadData.additionalData) else {
            return nil
        }
        self.additionalData = parsedData
        self.scannerId = payloadData.scannerId

        super.init(url: urlToParse)
    }

}

class TableSelfCheckin: SelfCheckin {
    var additionalData: TraceIdAdditionalData?
    var keyValues: [String: String]?
    var scannerId: String
    init?(urlToParse: URL) {

        guard let components = NSURLComponents(url: urlToParse, resolvingAgainstBaseURL: true),
              let componentArray = components.path?.split(separator: "/"),
              componentArray.first == "webapp" else {
            return nil
        }

        var urlStringToParse = urlToParse.absoluteString
        if let cwaRange = urlStringToParse.range(of: "/CWA1") {
            urlStringToParse.removeSubrange(cwaRange.lowerBound..<urlStringToParse.endIndex)
        }

        guard let payloadData = SelfCheckin.payloadData(from: urlStringToParse) else { return nil }

        if let parsedData = try? JSONDecoder().decode(TraceIdAdditionalData.self, from: payloadData.additionalData) {
            self.additionalData = parsedData
        } else if let keyValues = try? JSONSerialization.jsonObject(with: payloadData.additionalData, options: []) as? [String: Any] {
            self.keyValues = keyValues.mapValues { value in String(describing: value) }
        }
        self.scannerId = payloadData.scannerId

        super.init(url: urlToParse)
    }
}

class CheckInURLParser {
    static func parse(url: URL) -> SelfCheckin? {
        if let privateMeeting = PrivateMeetingSelfCheckin(urlToParse: url) {
            return privateMeeting
        } else if let tableSelfCheckin = TableSelfCheckin(urlToParse: url) {
            return tableSelfCheckin
        }
        return nil
    }
}

class SelfCheckinService {
    private var pendingSelfCheckin = BehaviorSubject<SelfCheckin?>(value: nil)
    var pendingSelfCheckinRx: Observable<SelfCheckin> {
        pendingSelfCheckin.asObservable().unwrapOptional()
            .delay(.milliseconds(10), scheduler: LucaScheduling.backgroundScheduler) // Reentrancy problem mitigation. Quick&dirty, will be fixed
    }
    func add(selfCheckinPayload payload: SelfCheckin) {
        pendingSelfCheckin.onNext(payload)
    }

    func consumeCurrent() {
        pendingSelfCheckin.onNext(nil)
    }
}
