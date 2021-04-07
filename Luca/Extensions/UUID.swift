import Foundation

extension UUID {
    var bytes: [UInt8] {
        var tuple = self.uuid
        return [UInt8](UnsafeBufferPointer(start: &tuple.0, count: MemoryLayout.size(ofValue: tuple)))
    }
}
