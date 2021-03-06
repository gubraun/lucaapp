import UIKit
import RxSwift
import JGProgressHUD

class DocumentViewController: UIViewController {

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyStateImageView: UIImageView!
    @IBOutlet weak var dataAccessView: UIView!
	@IBOutlet weak var notificationStackView: UIStackView!

    @IBOutlet weak var dataAccessHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    private var progressHud = JGProgressHUD.lucaLoading()

    weak var timeDifferenceView: TimeDifferenceView?

    private var disposeBag: DisposeBag?
    private var deleteDisposeBag: DisposeBag?

    private var documents = [Document]()
    private var testScannerNavController: UINavigationController?

    private var dataAccessHeight: CGFloat = 84
    private var noDataAccessHeight: CGFloat = 0

    private var accessedTraces: [AccessedTraceId] = []

    private let calendarURLString = "https://www.luca-app.de/coronatest/search"

    private let revalidationKey = "revalidationKey"

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

		setup()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAccessibility()

        installObservers()
		checkTimesync()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        disposeBag = nil
    }
}

// MARK: - Setup

extension DocumentViewController {

    private func setup() {
        notificationStackView.removeAllArrangedSubviews()

        setupStackView()
        setupApplicationStateObserver()
    }

    private func setupNavigationBar() {
        set(title: L10n.My.Luca.title)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // disable children functionallity for relead 1.10
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "addPersonWhite"), style: .plain, target: self, action: #selector(addTapped))
    }

    func setupStackView() {
        stackView.removeAllArrangedSubviews()

        let itemViews: [DocumentView] = documents.compactMap { DocumentViewFactory.createView(for: $0, with: self) }
        DocumentViewFactory.group(views: itemViews, with: self).forEach { stackView.addArrangedSubview($0) }
    }

    func setupAccessibilityViewsEmptyState() {
        self.view.accessibilityElements = [subtitleLabel, descriptionLabel, addButton].map { $0 as Any }
    }

    func setupAccessibilityViews() {
        self.view.accessibilityElements = [subtitleLabel, descriptionLabel, scrollView, addButton].map { $0 as Any }
    }

    private func installObservers() {
        let newDisposeBag = DisposeBag()

        revalidateIfNeeded()
            .andThen(loadDocuments())
            .subscribe()
            .disposed(by: newDisposeBag)

        // Observer for the data badge
        ServiceContainer.shared.accessedTracesChecker.accessedTraceIds
            .map { array in array.filter({ !$0.hasBeenSeenByUser }) }
            .logError(self, "Accessed trace IDs")
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { accessedTraces in
                self.accessedTraces = accessedTraces
                if accessedTraces.isEmpty {
                    self.hideDataAccess()
                } else {
                    self.dataAccess()
                }
            })
            .drive()
            .disposed(by: newDisposeBag)

        disposeBag = newDisposeBag
    }

    private func loadDocuments() -> Completable {
        ServiceContainer.shared.documentRepoService
            .currentAndNewTests
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .filter({ newDocuments in
                if self.documents.count != newDocuments.count { return true }
                return !self.documents.elementsEqual(newDocuments) { $0.originalCode == $1.originalCode }
            })
            .observe(on: MainScheduler.instance)
            .do(onNext: { docs in
                self.documents = docs.compactMap { $0 }
                self.updateViewControllerStyle()
                self.setupStackView()
            })
            .ignoreElementsAsCompletable()
    }

    private func getLastRevalidationDate() -> Single<Date?> {
        return ServiceContainer.shared.keyValueRepo.load(revalidationKey, type: Date?.self)
            .catch { _ in Single.just(nil) }
    }

    private func revalidateIfNeeded() -> Completable {
        return getLastRevalidationDate()
            .flatMapCompletable { date in

                if date == nil || !Calendar.current.isDateInToday(date!) {
                    let sc = ServiceContainer.shared
                    return sc.documentProcessingService.revalidateSavedTests()
                        .andThen(sc.keyValueRepo.store(self.revalidationKey, value: Date()))
                }

                return Completable.empty()
            }
    }

    private func setupApplicationStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }

    @objc
    func applicationDidEnterBackground(_ notification: NSNotification) {
        self.disposeBag = nil
        self.deleteDisposeBag = nil
        let scannerViewController = self.testScannerNavController?.viewControllers.first as? TestQRCodeScannerController
        scannerViewController?.scannerService?.endScanner()
        self.testScannerNavController?.dismiss(animated: true, completion: nil)
    }

    @objc
    func applicationDidBecomeActive(_ notification: NSNotification) {
        self.installObservers()
        self.checkTimesync()
    }

    private func updateViewControllerStyle() {
        let isEmptyState = documents.isEmpty
        scrollView.isHidden = isEmptyState
        subtitleLabel.isHidden = !isEmptyState
        descriptionLabel.isHidden = !isEmptyState
        emptyStateImageView.isHidden = !isEmptyState
        isEmptyState ? setupAccessibilityViewsEmptyState() : setupAccessibilityViews()
	}
}

// MARK: - Actions

extension DocumentViewController {
    @IBAction func dataAccessPressed(_ sender: UITapGestureRecognizer) {

        self.progressHud.show(in: self.view)

        _ = Observable.from(self.accessedTraces)
            .flatMap { AccessedTraceIdPairer.pairAccessedTraceProperties(accessedTraceId: $0) }
            .toArray()
            .map { dictsArray -> [HealthDepartment: [(TraceInfo, Location)]] in
                var retVal: [HealthDepartment: [(TraceInfo, Location)]] = [:]
                dictsArray.forEach { dict in
                    dict.forEach { entry in
                        retVal[entry.key] = entry.value
                    }
                }
                return retVal
            }
            .flatMap { dict in
                return ServiceContainer.shared.accessedTracesChecker
                    .consume(accessedTraces: self.accessedTraces)
                    .andThen(Single.just(dict))
            }
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { dict in
                self.showDataAccessAlert(accesses: dict)
            })
            .do(onDispose: { self.progressHud.dismiss() })
            .subscribe()
    }

    @IBAction private func calendarViewPressed(_ sender: UIButton) {
        if let url = URL(string: calendarURLString) {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func addTestPressed(_ sender: UIButton) {
        testScannerNavController = ViewControllerFactory.Document.createTestQRScannerViewController()
        if let scanner = testScannerNavController {
            scanner.modalPresentationStyle = .overFullScreen
            scanner.definesPresentationContext = true
            present(scanner, animated: true, completion: nil)
        }
    }

    @objc func addTapped() {
        let viewController = ViewControllerFactory.Children.createChildrenListViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Timesync

extension DocumentViewController {
    private func checkTimesync() {
        guard let disposeBag = disposeBag else { return }

        ServiceContainer.shared.backendMiscV3.fetchTimesync()
            .asSingle()
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { time in
                // only show the view, if there is a time difference > 5 min
                let isValid = (time.unix - 5 * 60) ... (time.unix + 5 * 60) ~= Int(Date().timeIntervalSince1970)
                isValid ? self.hideTimeDifferenceView() : self.showTimeDifferenceView()
            })
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func showTimeDifferenceView() {
        if timeDifferenceView == nil {
            timeDifferenceView = TimeDifferenceView.fromNib()
            notificationStackView.addArrangedSubview(timeDifferenceView!)
        }

        timeDifferenceView?.isHidden = false
    }

    private func hideTimeDifferenceView() {
        timeDifferenceView?.isHidden = true
    }
}

// MARK: - DataAccess

extension DocumentViewController {
    func dataAccess() {
        dataAccessView.isHidden = false
        dataAccessHeightConstraint.constant = dataAccessHeight
        setupAccessibilityViewOrder()
    }

    func hideDataAccess() {
        dataAccessView.isHidden = true
        dataAccessHeightConstraint.constant = noDataAccessHeight
        setupAccessibilityViewOrder()
    }

    private func showDataAccessAlert(onOk: (() -> Void)? = nil, accesses: [HealthDepartment: [(TraceInfo, Location)]]) {
        let alert = ViewControllerFactory.Alert.createDataAccessAlertViewController(accesses: accesses, allAccessesPressed: allAccessesPressed)
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        (self.tabBarController ?? self).present(alert, animated: true, completion: nil)
    }

    private func allAccessesPressed() {
        let viewController = ViewControllerFactory.Main.createDataAccessViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension DocumentViewController: UnsafeAddress, LogUtil {}

extension DocumentViewController {
    private func delete(document: Document) {
        let alert = UIAlertController.yesOrNo(title: L10n.Test.Delete.title, message: L10n.Test.Delete.description, onYes: {
            let newDisposeBag = DisposeBag()

            ServiceContainer.shared.documentProcessingService.remove(document: document)
                .do(onError: { error in
                    DispatchQueue.main.async {
                        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Test.Result.Delete.error)
                        self.present(alert, animated: true, completion: nil)
                    }
                })
                .subscribe()
                .disposed(by: newDisposeBag)
            self.deleteDisposeBag = newDisposeBag
        }, onNo: nil)

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Delegates

extension DocumentViewController: DocumentViewDelegate {
    func didToggleView() {}
    func deleteButtonPressed(for document: Document) {
        delete(document: document)
    }
}

extension DocumentViewController: HorizontalDocumentListViewDelegate {
    func didTapDelete(for document: Document) {
        delete(document: document)
    }
}

// MARK: - Accessibility
extension DocumentViewController {

    private func setupAccessibility() {
        dataAccessView.accessibilityTraits = .button
        dataAccessView.isAccessibilityElement = true
        dataAccessView.accessibilityLabel = L10n.Data.Access.Title.accessibility

        addButton.accessibilityLabel = L10n.Test.Add.title

        UIAccessibility.setFocusTo(navigationbarTitleLabel, notification: .layoutChanged, delay: 0.8)
    }

    private func setupAccessibilityViewOrder() {
        if documents.isEmpty && accessedTraces.isEmpty {
            // If no documents and no data access notification
            self.view.accessibilityElements = [subtitleLabel, descriptionLabel, addButton].map { $0 as Any }
        } else if documents.isEmpty {
            // If no documents but data access notification
            self.view.accessibilityElements = [dataAccessView, subtitleLabel, descriptionLabel, addButton].map { $0 as Any }
        } else if accessedTraces.isEmpty {
            // If no data access notification but documents
            self.view.accessibilityElements = [scrollView, addButton].map { $0 as Any }
        } else {
            // If have both
            self.view.accessibilityElements = [dataAccessView, scrollView, addButton].map { $0 as Any }
        }
    }

}
