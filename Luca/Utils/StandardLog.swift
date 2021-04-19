import Foundation
import os.log

class StandardLog: LogUtil {
    var subsystem: String

    var category: String

    var subDomains: [String]

    private var logger: OSLog

    func log(_ message: String, entryType: LogUtilEntryType = .info) {
        let subDomainsString = subDomains.reduce("") { (result, element) -> String in
            return "\(result)[\(element)] "
        }
        os_log(entryType.logType, log: logger, "%{public}@%{public}@", subDomainsString, message)
    }

    init(subsystem: String, category: String, subDomains: [String]) {
        self.subsystem = subsystem
        self.category = category
        self.subDomains = subDomains

        logger = OSLog(subsystem: subsystem, category: category)
    }
}
