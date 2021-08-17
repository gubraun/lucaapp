import UIKit
import RxSwift
import JGProgressHUD

public class DeleteAccountCoordinator: NSObject, Coordinator {

    private let presenter: UIViewController

    private let progressHUD = JGProgressHUD.lucaLoading()

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {
        UIAlertController(title: L10n.Data.ResetData.title,
                          message: L10n.Data.ResetData.description,
                          preferredStyle: .alert)
            .actionAndCancelAlert(actionText: L10n.Data.ResetData.title, action: {
                self.deleteUser()
            }, viewController: presenter)
    }

    private func deleteUser() {
        progressHUD.show(in: presenter.view)
        _ = ServiceContainer.shared.documentRepoService
            .currentAndNewTests
            .take(1)
            .asSingle()
            .flatMapCompletable { docs in
                ServiceContainer.shared.documentUniquenessChecker.release(documents: docs)
            }
            .andThen(deleteUserData())
            .observe(on: MainScheduler.instance)
            .do(onError: { error in
                if let localizedTitledError = error as? LocalizedTitledError {
                    let alert = UIAlertController.infoAlert(
                        title: localizedTitledError.localizedTitle,
                        message: localizedTitledError.localizedDescription
                    )
                    self.presenter.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController.infoAlert(
                        title: L10n.Navigation.Basic.error,
                        message: error.localizedDescription
                    )
                    self.presenter.present(alert, animated: true, completion: nil)
                }
            })
            .do(onDispose: {
                self.progressHUD.dismiss()
            })
            .subscribe()
    }

    private func deleteUserData() -> Completable {
        ServiceContainer.shared.userService.deleteUserData()
            .subscribe(on: MainScheduler.instance)
            .catch({ error in

                // In case account was already deleted, or account doesn't exist, reset app and begin onboarding.
                if let deleteError = error as? UserServiceError,
                   case let UserServiceError.userDeletionError(error: backendError) = deleteError,
                   backendError.backendError == .alreadyDeleted || backendError.backendError == .userNotFound {
                    return Completable.empty()
                }

                throw error
            })
            .andThen(Completable.from {
                self.presenter.dismiss(animated: true, completion: nil)
                DataResetService.resetAll()
            })
    }
}
