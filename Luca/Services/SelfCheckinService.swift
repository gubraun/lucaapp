import Foundation
import RxSwift
import base64url

struct SelfCheckInPayload {
    var scannerId: String
    var additionalData: String
}

class SelfCheckin {
    var url: URL
    init(url: URL) {
        self.url = url
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
        
        guard let parameters = urlToParse.absoluteString.split(separator: "/").last else {
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
        
        guard let parsedData = try? JSONDecoder().decode(PrivateMeetingQRCodeV3AdditionalData.self, from: data) else {
            return nil
        }
        self.additionalData = parsedData
        self.scannerId = String(scannerId)
        
        super.init(url: urlToParse)
    }
}

class TableSelfCheckin: SelfCheckin {
    var additionalData: TraceIdAdditionalData? = nil
    var keyValues: [String: String]? = nil
    var scannerId: String
    init?(urlToParse: URL) {
        
        guard let components = NSURLComponents(url: urlToParse, resolvingAgainstBaseURL: true),
              let componentArray = components.path?.split(separator: "/"),
              componentArray.count == 2,
              componentArray.first == "webapp" else {
            return nil
        }
        
        guard let parameters = urlToParse.absoluteString.split(separator: "/").last else {
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
        
        if let parsedData = try? JSONDecoder().decode(TraceIdAdditionalData.self, from: data) {
            self.additionalData = parsedData
        } else if let keyValues = try? JSONDecoder().decode([String: String].self, from: data) {
            self.keyValues = keyValues
        }
        self.scannerId = String(scannerId)
        
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
            .delay(.milliseconds(10), scheduler: LucaScheduling.backgroundScheduler) //Reentrancy problem mitigation. Quick&dirty, will be fixed
    }
    func add(selfCheckinPayload payload: SelfCheckin) {
        pendingSelfCheckin.onNext(payload)
    }
    
    func consumeCurrent() {
        pendingSelfCheckin.onNext(nil)
    }
}
