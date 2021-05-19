import UIKit
import RxSwift
import RxAppState

extension Reactive where Base == UIApplication {
    var currentAndChangedAppState: Observable<AppState> {
        let current = Single.from { AppState(state: base.applicationState) }
        return Observable.merge(appState, current.asObservable()).subscribe(on: MainScheduler.instance)
    }
}

extension AppState {
    init(state: UIApplication.State) {
        switch state {
        case .active:
            self = .active
        case .background:
            self = .background
        case .inactive:
            self = .inactive
        @unknown default:
            self = .inactive
        }
    }
}
