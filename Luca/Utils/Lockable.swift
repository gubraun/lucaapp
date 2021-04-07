import Foundation

// Object used solely for locking and releasing synchronizations
public class LockSynchronizer: NSObject {}

// Watch out for the _swiftEmptyDictionaryStorage! Empty dictionaries are actually NOT allocated! The new dictionaries without content are references of this mysterious _swiftEmptyDictionaryStorage. So, when entering a lock with this reference and exitting after filling the dictionary with data, you are locking and releasing two different objects.
public func synchronized<T>(_ lock: LockSynchronizer, closure: () throws -> T) rethrows -> T {
    defer { objc_sync_exit(lock) }
    objc_sync_enter(lock)
    return try closure()
}

public func synchronized<T>(_ lock: LockSynchronizer, closure: () -> T) -> T {
    defer { objc_sync_exit(lock) }
    objc_sync_enter(lock)
    return closure()
}

public class Lockable<U> {
    var target: U
    private var lock = LockSynchronizer()
    private var locked = false
    public init(target: U) {
        self.target = target
    }
    
    public func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        defer {
            objc_sync_exit(lock)
            locked = false
        }
        let lockedAlready = locked
        if self.locked {
            self.log("Locking Lockable that has been locked already! Waiting for unlock...", entryType: .error)
        }
        objc_sync_enter(lock)
        if lockedAlready {
            self.log("Unlock!")
        }
        locked = true
        return try closure()
    }

    public func synchronized<T>(_ closure: () -> T) -> T {
        defer {
            objc_sync_exit(lock)
            locked = false
        }
        let lockedAlready = locked
        if self.locked {
            self.log("Locking Lockable that has been locked already! Waiting for unlock...", entryType: .error)
        }
        objc_sync_enter(lock)
        if lockedAlready {
            self.log("Unlock!")
        }
        locked = true
        return closure()
    }
}

extension Lockable {
    func synchronized<T>(_ closure: (U) -> T) -> T {
        self.synchronized { closure(self.target) }
    }
    
    func synchronized<T>(_ closure: (U) throws -> T) rethrows -> T {
        try self.synchronized { try closure(self.target) }
    }
}

extension Lockable: LogUtil, UnsafeAddress {}
