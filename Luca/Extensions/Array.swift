import Foundation

extension Array where Element: Hashable {
    
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
    
}

public extension Array where Element: OptionalType {
    
    func unwrapOptional() -> Array<Element.Wrapped> {
        return try self.filter { (value) in
            if value.value == nil {
                return false
            }
            return true
        }
        .map { $0.value! }
    }
    
}
