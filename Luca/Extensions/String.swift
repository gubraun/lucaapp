import Foundation

extension String {
    static func isNilOrEmpty(_ string: String?) -> Bool {
        return string == nil || string == ""
    }
    func split(every length:Int) -> [Substring] {
        guard length > 0 && length < count else { return [suffix(from:startIndex)] }

        return (0 ... (count - 1) / length).map { dropFirst($0 * length).prefix(length) }
    }

    func split(backwardsEvery length:Int) -> [Substring] {
        guard length > 0 && length < count else { return [suffix(from:startIndex)] }

        return (0 ... (count - 1) / length).map { dropLast($0 * length).suffix(length) }.reversed()
    }
    
    static func hex(from value: Int) -> String {
        String(format:"%02X", value)
    }
    
    func base64ToHex() -> String? {
        let data = Data(base64Encoded: self)
        return data?.toHexString()
    }
}

extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }
    func distance<S: StringProtocol>(of string: S) -> Int? { range(of: string)?.lowerBound.distance(in: self) }
}

extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}
