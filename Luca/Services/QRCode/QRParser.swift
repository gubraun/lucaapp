import Foundation
import RxSwift

class QRParser {

    private let documentFactory: DocumentFactory

    init(documentFactory: DocumentFactory) {
        self.documentFactory = documentFactory
    }

    // Parses the qr code. Returns an error if the qr is neither a checkin, document, or URL.
    public func processQRType(qr: String) -> Single<QRType> {
        parseCheckin(qr: qr)
            .catch { _ in self.parseDocument(qr: qr) }
            .catch { _ in self.parseURL(qr: qr) }
    }

    private func parseCheckin(qr: String) -> Single<QRType> {
        Single.from {
            guard let url = URL(string: qr), CheckInURLParser.parse(url: url) != nil else {
                throw QRProcessingError.parsingFailed
            }
            return .checkin
        }
    }

    private func parseDocument(qr: String) -> Single<QRType> {
        documentFactory.createDocument(from: qr)
            .asCompletable()
            .andThen(Single.from { QRType.document })
    }

    private func parseURL(qr: String) -> Single<QRType> {
        Single.from {
            guard let url = URL(string: qr), UIApplication.shared.canOpenURL(url) else {
                throw QRProcessingError.parsingFailed
            }
            return .url
        }.subscribe(on: MainScheduler.instance)
    }

}
