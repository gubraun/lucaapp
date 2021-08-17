import Foundation

class ViewControllerFactory {
    static var Onboarding = OnboardingViewControllerFactory.self
    static var Main = MainViewControllerFactory.self
    static var Checkin = CheckinViewControllerFactory.self
    static var Document = DocumentViewControllerFactory.self
    static var History = HistoryViewControllerFactory.self
    static var Account = AccountViewControllerFactory.self
    static var Terms = TermsViewControllerFactory.self
    static var Alert = AlertViewControllerFactory.self
}
