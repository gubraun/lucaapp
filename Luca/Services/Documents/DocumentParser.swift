import Foundation
import RxSwift

protocol Document {

    /// Unique identifier to differentiate between documents
    var identifier: Int { get }

    /// Serialized string
    var originalCode: String { get }

}

protocol DocumentParser {
    func parse(code: String) -> Single<Document>
}
