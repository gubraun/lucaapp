import Foundation
import RxSwift
import RealmSwift

class CoronaTestFactory {

    func createCoronaTest(from testCode: String) -> Single<CoronaTest> {
        TicketIOCoronaTest.decodeTestCode(parse: testCode)
//                            .catch { _ in UbirchCoronaTest.decodeTestCode(parse: testCode) }
            .catch { _ in BaerCoronaTest.decodeTestCode(parse: testCode) }
            .catch { _ in SodaCoronaTest.decodeTestCode(parse: testCode) }
            .catch { _ in MeinCoronaTest.decodeTestCode(parse: testCode) }
            .catch { _ in TestNowCoronaTest.decodeTestCode(parse: testCode) }
            .catch { _ in DmCoronaTest.decodeTestCode(parse: testCode) }
            .catch { _ in Single<CoronaTest>.error(CoronaTestProcessingError.parsingFailed) }
    }

}
