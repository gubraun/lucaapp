import Foundation
import RxSwift

protocol Document {

    /// Unique identifier to differentiate between documents
    var identifier: Int { get }

    /// Serialized string
    var originalCode: String { get }

    /// Safe string that is used for hash generation. It's based on `originalCode` but stripped from all hash-irrelevant stuff to provide uniqueness.
    var hashSeed: String { get }

    /// Date until this document is valid
    var expiresAt: Date { get }

}

protocol DocumentParser {
    func parse(code: String) -> Single<Document>
}
