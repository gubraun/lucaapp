import Foundation
import os.log

public enum LogUtilEntryType {
    case info
    case warning
    case error
    case debug
    
    /// For system level or multiprocessing errors only
    case fault
}

extension LogUtilEntryType {
    var logType: OSLogType {
        switch self {
        case .info:
            return .default
        case .debug:
            return .debug
        case .error:
            return .error
        case .warning:
            return .error
        case .fault:
            return .fault
        }
    }
}

fileprivate var loggers = Lockable<[Int: OSLog]>(target: [:])

public protocol LogUtil {
    
    /// Primary categorisation criteria. Example: Authentication for the Auth SDK or App for the App
    var subsystem: String { get }
    
    /// Secondary categorisation criteria. Default: name of the class
    var category: String { get }
    
    /// Further criteria. Will be attached as message. Useful for differentiating mutliple instances of the same category. Default empty
    var subDomains: [String] { get }
    func log(_ message: String, entryType: LogUtilEntryType)
}

/// Using this standard logic is very easy and lightweight. It has however a downside: it sets mutex wherever the global loggers dictionary is reached.
public extension LogUtil where Self: UnsafeAddress {
    
    var subsystem: String {
        return "App"
    }
    
    var category: String {
        return String(describing: type(of: self))
    }
    
    var subDomains: [String] { [] }
    
    private var logger: OSLog {
        let address = unsafeAddress
        
        return loggers.synchronized {
            if let foundLogger = loggers.target[address] {
                return foundLogger
            }
            let newLogger = OSLog(subsystem: subsystem, category: category)
            loggers.target[address] = newLogger
            return newLogger
        }
    }
    
    func log(_ message: String, entryType: LogUtilEntryType = .info) {
        let subDomainsString = subDomains.reduce("") { (result, element) -> String in
            return "\(result)[\(element)] "
        }
        os_log(entryType.logType, log: logger, "%{public}@%{public}@", subDomainsString, message)
    }
}

public class GeneralPurposeLog: LogUtil {
    
    public let subsystem: String
    public let category: String
    public let subDomains: [String]
    
    private let logger: OSLog
    
    init(subsystem: String, category: String, subDomains: [String]) {
        self.subsystem = subsystem
        self.category = category
        self.subDomains = subDomains
        logger = OSLog(subsystem: subsystem, category: category)
    }
    
    public func log(_ message: String, entryType: LogUtilEntryType) {
        let subDomainsString = subDomains.reduce("") { (result, element) -> String in
            return "\(result)[\(element)] "
        }
        os_log(entryType.logType, log: logger, "%{public}@%{public}@", subDomainsString, message)
    }
}
