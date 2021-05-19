import Foundation
import RxSwift

/// Default minimal implementation of CoronaTest for CoronaTestRepo handling.
struct CoronaTestPayload: DataRepoModel {
    var originalCode: String
    var identifier: Int?
}
