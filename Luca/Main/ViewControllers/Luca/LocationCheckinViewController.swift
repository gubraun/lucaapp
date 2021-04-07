import UIKit
import JGProgressHUD
import CoreLocation
import RxSwift
import RxCocoa
import RxAppState

class LocationCheckinViewController: UIViewController {
    
    @IBOutlet weak var checkinSlider: CheckinSlider!
    @IBOutlet weak var sliderDescriptionLabel: UILabel!
    @IBOutlet weak var checkinDateLabel: UILabel!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var automaticCheckoutSwitch: UISwitch!
    @IBOutlet weak var checkOutLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var tableNumberLabel: UILabel!
    @IBOutlet weak var automaticCheckoutLabel: UILabel!
    
    var viewModel: LocationCheckInViewModel!
    
    var gradient = CAGradientLayer()
    var initialStatusBarStyle: UIStatusBarStyle?
    
    var loadingHUD = JGProgressHUD.lucaLoading()
    
    var widthSEConstraint: CGFloat = 320
    
    private var autoCheckoutDisposeBag = DisposeBag()
    private var userStatusFetcherDisposeBag: DisposeBag?
    private var checkOutDisposeBag: DisposeBag? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setTranslucent()
        
        checkinSlider.addTarget(self, action: #selector(checkinSliderMoved(_:)), for: .valueChanged)
        checkinSlider.addTarget(self, action: #selector(checkinSliderDoneMoving(_:)), for: .touchUpInside)
        NotificationPermissionHandler.shared.requestAuthorization(viewController: self)
        
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        initialStatusBarStyle = UIApplication.shared.statusBarStyle
        if #available(iOS 13.0, *) {
            UIApplication.shared.setStatusBarStyle(.darkContent, animated: animated)
        } else {
            UIApplication.shared.setStatusBarStyle(.default, animated: animated)
        }

        installObservers()
        print("TEST: Will appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        removeObservers()

        if let statusBarStyle = initialStatusBarStyle {
            UIApplication.shared.setStatusBarStyle(statusBarStyle, animated: animated)
        }
        
        userStatusFetcherDisposeBag = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        checkinSlider.value = checkinSlider.maxValue
    }
    
    @objc func checkinSliderMoved(_ checkinSlider: CheckinSlider) {
        if checkinSlider.value == checkinSlider.minValue {
            self.resetCheckInSlider()
            if checkOutDisposeBag != nil {
                return
            }
            
            let disposeBag = DisposeBag()
            
            viewModel.checkOut()
                .observeOn(MainScheduler.instance)
                .logError(self, "Check out")
                .do(onError: { (error) in
                    if let printableError = error as? PrintableError {
                        let alert = UIAlertController.infoAlert(
                            title: printableError.title,
                            message: printableError.message)
                        self.present(alert, animated: true, completion: nil)
                    }
                }, onDispose: {
                    self.checkOutDisposeBag = nil
                })
                .onErrorComplete()
                .subscribe()
                .disposed(by: disposeBag)
            
            checkOutDisposeBag = disposeBag
            
        } else {
            self.checkOutLabel.alpha = checkinSlider.value / (checkinSlider.maxValue - checkinSlider.minValue)
        }
    }
    
    @objc func checkinSliderDoneMoving(_ checkinSlider: CheckinSlider) {
        if checkinSlider.value != checkinSlider.minValue {
            checkinSlider.value = checkinSlider.maxValue
            checkOutLabel.isHidden = false
            checkOutLabel.alpha = 1.0
        }
    }
    
    private func resetCheckInSlider() {
        checkinSlider.value = checkinSlider.maxValue
        checkOutLabel.isHidden = false
        checkOutLabel.alpha = 1.0
    }

    @IBAction func viewMorePressed(_ sender: UITapGestureRecognizer) {
        UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet).dataPrivacyActionSheet(viewController: self)
    }
    
    // MARK: View setup functions.
    
    func setupViews() {
        if view.frame.size.width <= widthSEConstraint {
            sliderDescriptionLabel.font = UIFont.montserratRegularTimer
        }
        
        welcomeLabel.text = L10n.LocationCheckinViewController.welcomeMessage
        checkinSlider.value = checkinSlider.maxValue
        navigationItem.hidesBackButton = true
        
        gradient.frame = view.bounds
        gradient.colors = [UIColor.lucaLightGreen.cgColor, UIColor.lucaGreen.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private func installObservers() {
        
        let newDisposeBag = DisposeBag()
        
        viewModel.isCheckedIn
            .do { (isCheckedIn) in
                if !isCheckedIn {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            .drive()
            .disposed(by: newDisposeBag)
        
        viewModel.isBusy.do { (busy) in
            if busy {
                self.loadingHUD.show(in: self.view)
            } else {
                self.loadingHUD.dismiss()
            }
        }
        .drive()
        .disposed(by: newDisposeBag)
        
        viewModel.alert
            .asObservable()
            .flatMapFirst { alert in
                return UIAlertController.infoAlertRx(viewController: self, title: alert.title, message: alert.message)
            }
            .subscribe()
            .disposed(by: newDisposeBag)
        
        viewModel.additionalDataLabelHidden
            .drive(tableNumberLabel.rx.isHidden)
            .disposed(by: newDisposeBag)
        
        viewModel.additionalDataLabelText
            .drive(tableNumberLabel.rx.text)
            .disposed(by: newDisposeBag)
        
        viewModel.time
            .drive(self.sliderDescriptionLabel.rx.text)
            .disposed(by: newDisposeBag)
        
        viewModel.isAutoCheckoutAvailable
            .map { !$0 }
            .drive(self.automaticCheckoutSwitch.rx.isHidden)
            .disposed(by: newDisposeBag)
        
        viewModel.isAutoCheckoutAvailable
            .map { !$0 }
            .drive(self.automaticCheckoutLabel.rx.isHidden)
            .disposed(by: newDisposeBag)
        
        viewModel.checkInTime
            .drive(checkinDateLabel.rx.text)
            .disposed(by: newDisposeBag)
        
        Driver.combineLatest(viewModel.groupName, viewModel.locationName).drive(onNext: { [weak self] (groupName, locationName) in
            self?.setupLocationLabels(with: groupName, and: locationName)
        }).disposed(by: newDisposeBag)
        
        (automaticCheckoutSwitch.rx.value <-> viewModel.isAutoCheckoutEnabled).disposed(by: newDisposeBag)
        
        viewModel.connect(viewController: self)
        
        userStatusFetcherDisposeBag = newDisposeBag
        
        print("TEST: Install observers")
    }
    
    private func removeObservers() {
        userStatusFetcherDisposeBag = nil
        viewModel.release()
        print("TEST: Remove observers")
    }
    
    private func setupLocationLabels(with groupName: String?, and locationName: String?) {
        switch (groupName, locationName) {
        case (.some(let groupName), .some(let locationName)):
            groupNameLabel.text = groupName
            locationNameLabel.text = locationName
            locationNameLabel.textColor = .black
        case (.some(let groupName), nil):
            groupNameLabel.text = nil
            locationNameLabel.text = groupName
            locationNameLabel.textColor = .black
        default:
            break
        }
    }
}

extension LocationCheckinViewController: UnsafeAddress, LogUtil {}
