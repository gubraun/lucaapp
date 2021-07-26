import UIKit
import RxSwift

protocol DocumentCellDelegate: AnyObject {
    func deleteButtonPressed(for document: Document)
}

class HealthViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyStateImageView: UIImageView!

    private var disposeBag: DisposeBag?
    private var deleteDisposeBag: DisposeBag?

    private var viewModels = [DocumentCellViewModel]()

    private var collapsedCellHeight: CGFloat = 100
    private var expandedCellIndices = [IndexPath]()
    private var testScanner: TestQRCodeScannerController?

    private let calendarURLString = "https://www.luca-app.de/coronatest/search"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        setupTitle()
        installObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleLabel.isAccessibilityElement = true
        UIAccessibility.setFocusLayout(titleLabel)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        disposeBag = nil
        deleteDisposeBag = nil
    }

    private func setupTitle() {
        guard let firstName = LucaPreferences.shared.firstName, let lastName = LucaPreferences.shared.lastName else {
            titleLabel.text = L10n.My.Luca.title
            return
        }
        titleLabel.text = "\(firstName) \(lastName)"
    }

    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear

        // Recovery cell
        let recoveryCellNib = UINib(nibName: "CoronaRecoveryTableViewCell", bundle: nil)
        tableView.register(recoveryCellNib, forCellReuseIdentifier: "CoronaRecoveryTableViewCell")
    }

    private func installObservers() {
        let newDisposeBag = DisposeBag()

        _ = ServiceContainer.shared.documentProcessingService.revalidateSavedTests().subscribe()

        ServiceContainer.shared.documentRepoService
            .currentAndNewTests
            .subscribe(onNext: { tests in

                self.viewModels = tests.compactMap { $0 as? DocumentCellViewModel }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.updateViewControllerStyle()
                }
            })
            .disposed(by: newDisposeBag)

        UIApplication.shared.rx.applicationDidEnterBackground
            .subscribe(onNext: { _ in
                self.testScanner?.endScanner()
                self.testScanner?.dismiss(animated: true, completion: nil)
            }).disposed(by: newDisposeBag)

        disposeBag = newDisposeBag
    }

    func setupAccessibilityViewsEmptyState() {
        self.view.accessibilityElements = [titleLabel, subtitleLabel, descriptionLabel, addButton].map { $0 as Any }
    }

    func setupAccessibilityViews() {
        self.view.accessibilityElements = [titleLabel, subtitleLabel, descriptionLabel, tableView, addButton].map { $0 as Any }
    }

    @IBAction private func calendarViewPressed(_ sender: UIButton) {
        if let url = URL(string: calendarURLString) {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func addTestPressed(_ sender: UIButton) {
        testScanner = MainViewControllerFactory.createTestQRScannerViewController()
        if let scanner = testScanner {
            scanner.modalPresentationStyle = .overFullScreen
            scanner.definesPresentationContext = true
            present(scanner, animated: true, completion: nil)
        }
    }

    private func updateViewControllerStyle() {
        let isEmptyState = viewModels.isEmpty
        tableView.isHidden = isEmptyState
        subtitleLabel.isHidden = !isEmptyState
        descriptionLabel.isHidden = !isEmptyState
        emptyStateImageView.isHidden = !isEmptyState
        isEmptyState ? setupAccessibilityViewsEmptyState() : setupAccessibilityViews()
    }

}
extension HealthViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        // Use sections instead of rows in order to have section footers between rows
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = viewModels[indexPath.section]
        return viewModel.dequeueCell(tableView, indexPath, delegate: self)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return expandedCellIndices.contains(indexPath) ? UITableView.automaticDimension : collapsedCellHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return expandedCellIndices.contains(indexPath) ? UITableView.automaticDimension : collapsedCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        expandedCellIndices.append(indexPath)
        didPress(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        expandedCellIndices.removeAll(where: { $0 == indexPath})
        didPress(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func didPress(indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

extension HealthViewController: DocumentCellDelegate {
    func deleteButtonPressed(for document: Document) {
        let alert = UIAlertController.yesOrNo(title: L10n.Test.Delete.title, message: L10n.Test.Delete.description, onYes: {
            let identifier = document.identifier
            let newDisposeBag = DisposeBag()

            ServiceContainer.shared.documentRepoService.remove(identifier: identifier)
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
