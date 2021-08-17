import Foundation
import RxSwift
import JGProgressHUD

class QRProcessingService {

    private let documentProcessingService: DocumentProcessingService
    private let qrParser: QRParser
    private let selfCheckinService: SelfCheckinService

    init(documentProcessingService: DocumentProcessingService, documentFactory: DocumentFactory, selfCheckinService: SelfCheckinService) {
        self.documentProcessingService = documentProcessingService
        self.qrParser = QRParser(documentFactory: documentFactory)
        self.selfCheckinService = selfCheckinService
    }

    public func processQRCode(qr: String, viewController: QRScannerViewController) -> Completable {
        qrParser.processQRType(qr: qr)
            .flatMapMaybe { self.showAlertIfWrongType(viewController: viewController, type: $0) }
            .asObservable()
            .flatMap { type -> Completable in
                switch type {
                case .checkin: return self.checkin(qr: qr)
                case .document: return self.processDocument(url: qr, viewController: viewController)
                case .url: return self.openURL(qr: qr)
                }
            }.asCompletable()
    }

    private func checkin(qr: String) -> Completable {
        Completable.from {
            guard let url = URL(string: qr), let checkin = CheckInURLParser.parse(url: url) else {
                throw QRProcessingError.parsingFailed
            }
            self.selfCheckinService.add(selfCheckinPayload: checkin)
        }
    }

    private func processDocument(url: String, viewController: UIViewController) -> Completable {
        showTestPrivacyConsent(viewController: viewController)
            .asObservable()
            .flatMap { _ in self.documentProcessingService.parseQRCode(qr: url) }
            .ignoreElementsAsCompletable()
    }

    private func openURL(qr: String) -> Completable {
        Completable.from {
            guard let url = URL(string: qr) else {
                throw QRProcessingError.parsingFailed
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }.subscribe(on: MainScheduler.instance)
    }

    // MARK: Alerts

    func showAlertIfWrongType(viewController: QRScannerViewController, type: QRType) -> Maybe<QRType> {
        return Maybe.create { observer -> Disposable in
            let showAlert = viewController.type != type && type != .url
            let title = viewController.type == .checkin ? L10n.Camera.Warning.Checkin.title : L10n.Camera.Warning.Document.title
            let message = viewController.type == .checkin ? L10n.Camera.Warning.Checkin.description : L10n.Camera.Warning.Document.description
                let alert = UIAlertController
                    .actionAndCancelAlert(viewController: viewController, title: title, message: message, actionTitle: L10n.Navigation.Basic.continue, action: {
                        observer(.success(type))
                    }, cancelAction: {
                        observer(.completed)
                    })
                showAlert ? viewController.present(alert, animated: true, completion: nil) : observer(.success(type))

            return Disposables.create { alert.dismiss(animated: true, completion: nil) }
        }.subscribe(on: MainScheduler.instance)
    }

    func showTestPrivacyConsent(viewController: UIViewController) -> Maybe<Void> {
        return Maybe.create { observer -> Disposable in
            let alert = ViewControllerFactory.Alert.createTestPrivacyConsent(confirmAction: {
                observer(.success(Void()))
            }, cancelAction: {
                observer(.completed)
            })
            alert.modalTransitionStyle = .crossDissolve
            alert.modalPresentationStyle = .overCurrentContext
            viewController.present(alert, animated: true, completion: nil)

            return Disposables.create { alert.dismiss(animated: true, completion: nil) }
        }.subscribe(on: MainScheduler.instance)
    }

}
