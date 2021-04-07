import Foundation

public protocol UnsafeAddress {
    var unsafeAddress: Int { get }
}

/// May be used only on a reference types
public extension UnsafeAddress where Self: AnyObject {
    var unsafeAddress: Int {
        unsafeBitCast(self, to: Int.self)
    }
}
