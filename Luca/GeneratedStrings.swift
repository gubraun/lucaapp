// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Licenses
  internal static let acknowledgements = L10n.tr("Localizable", "Acknowledgements")

  internal enum Button {
    internal enum Private {
      /// Create private meeting
      internal static let meeting = L10n.tr("Localizable", "button.private.meeting")
    }
    internal enum Scanner {
      /// Self check-in
      internal static let checkin = L10n.tr("Localizable", "button.scanner.checkin")
    }
  }

  internal enum Camera {
    internal enum Access {
      /// Once you've granted access, you can scan QR codes within your luca app.
      internal static let description = L10n.tr("Localizable", "camera.access.description")
      /// luca needs to access your camera
      internal static let title = L10n.tr("Localizable", "camera.access.title")
    }
    internal enum Error {
      /// Your device cannot be used to scan.
      internal static let scanningFailed = L10n.tr("Localizable", "camera.error.scanningFailed")
      /// The QR code is not valid.
      internal static let wrongQR = L10n.tr("Localizable", "camera.error.wrongQR")
    }
  }

  internal enum Checkin {
    /// Check-in
    internal static let noun = L10n.tr("Localizable", "checkin.noun")
    internal enum Failure {
      internal enum AlreadyCheckedIn {
        /// You are already checked in.
        internal static let message = L10n.tr("Localizable", "checkin.failure.alreadyCheckedIn.message")
      }
      internal enum MissingIsPrivateFlag {
        /// Check-in not possible. Apparently, this QR-Code is not valid.
        internal static let message = L10n.tr("Localizable", "checkin.failure.missingIsPrivateFlag.message")
      }
      internal enum NotAvailableAnymore {
        /// It is not possible to check in here any more.
        internal static let message = L10n.tr("Localizable", "checkin.failure.notAvailableAnymore.message")
      }
      internal enum PrivateMeetingRunning {
        /// You can't check in while you are hosting a private meeting. End the meeting and try again.
        internal static let message = L10n.tr("Localizable", "checkin.failure.privateMeetingRunning.message")
      }
    }
    internal enum Qr {
      /// This is your QR code. For check-in, have it scanned at a place that uses luca.
      internal static let description = L10n.tr("Localizable", "checkin.qr.description")
      /// Check-in
      internal static let title = L10n.tr("Localizable", "checkin.qr.title")
    }
    internal enum Scanner {
      /// Scan the QR code of a place that uses luca or a private meeting to check yourself in.
      internal static let description = L10n.tr("Localizable", "checkin.scanner.description")
      /// Self check-in
      internal static let title = L10n.tr("Localizable", "checkin.scanner.title")
    }
    internal enum Slider {
      /// Check-in: %@
      internal static func date(_ p1: Any) -> String {
        return L10n.tr("Localizable", "checkin.slider.date", String(describing: p1))
      }
      /// dd.MM.yyyy HH:mm
      internal static let dateFormat = L10n.tr("Localizable", "checkin.slider.dateFormat")
    }
  }

  internal enum Checkout {
    /// Checkout
    internal static let noun = L10n.tr("Localizable", "checkout.noun")
  }

  internal enum Contact {
    internal enum Qr {
      internal enum Accessibility {
        /// QR Code
        internal static let qrCode = L10n.tr("Localizable", "contact.qr.accessibility.qrCode")
        /// QR Code Scanner
        internal static let qrCodeScanner = L10n.tr("Localizable", "contact.qr.accessibility.qrCodeScanner")
      }
      internal enum Button {
        /// CLOSE QR CODE SCANNER
        internal static let closeScanner = L10n.tr("Localizable", "contact.qr.button.closeScanner")
        /// SELF CHECK-IN
        internal static let selfCheckin = L10n.tr("Localizable", "contact.qr.button.selfCheckin")
      }
    }
  }

  internal enum ContactViewController {
    /// Save
    internal static let save = L10n.tr("Localizable", "contactViewController.save")
    internal enum EmptyAddress {
      /// You must enter a complete address!
      internal static let message = L10n.tr("Localizable", "contactViewController.emptyAddress.message")
    }
    internal enum EmptyRest {
      /// You must fill out all fields.
      internal static let message = L10n.tr("Localizable", "contactViewController.emptyRest.message")
    }
    internal enum SaveFailed {
      /// Save failed: %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "contactViewController.saveFailed.message", String(describing: p1))
      }
    }
    internal enum ShouldSave {
      /// Apply all changes? If you've changed your name and it doesn't match the name in your imported tests, these might be deleted.
      internal static let message = L10n.tr("Localizable", "contactViewController.shouldSave.message")
      /// Save changes
      internal static let title = L10n.tr("Localizable", "contactViewController.shouldSave.title")
    }
  }

  internal enum DailyKey {
    internal enum Fetch {
      internal enum FailedToDownload {
        /// The luca Service is currently not available, please try again later.
        internal static let message = L10n.tr("Localizable", "dailyKey.fetch.failedToDownload.message")
      }
      internal enum FailedToSave {
        /// The daily key could not be saved! %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dailyKey.fetch.failedToSave.message", String(describing: p1))
        }
      }
    }
  }

  internal enum Data {
    internal enum Access {
      /// New data request
      internal static let title = L10n.tr("Localizable", "data.access.title")
      internal enum Notification {
        /// A health department has requested your contact data.
        internal static let description = L10n.tr("Localizable", "data.access.notification.description")
      }
      internal enum Title {
        /// Show new data request
        internal static let accessibility = L10n.tr("Localizable", "data.access.title.accessibility")
      }
    }
    internal enum Clear {
      /// Do you really want to clear your history?\n\nPast entries won't be displayed in your app anymore, but will stay in the system for up to 30 days and will be shared with the health authorities if you share your data.
      internal static let description = L10n.tr("Localizable", "data.clear.description")
      /// Clear history
      internal static let title = L10n.tr("Localizable", "data.clear.title")
    }
    internal enum ResetData {
      /// Do you really want to delete your account?\n\nIf you delete your account, you will not be able to check in or access your history.\n\nIn accordance with the Corona/COVID-19 infection control regulations, all encrypted check-in data will be deleted after 4 weeks.\n\nOnce your account is deleted, you can still be notified by a health department up to 4 weeks after your last check-in.
      internal static let description = L10n.tr("Localizable", "data.resetData.description")
      /// Delete account
      internal static let title = L10n.tr("Localizable", "data.resetData.title")
    }
    internal enum Shared {
      /// You have shared your check-ins from the last %@ days with the health department.
      internal static func description(_ p1: Any) -> String {
        return L10n.tr("Localizable", "data.shared.description", String(describing: p1))
      }
      /// Data shared
      internal static let title = L10n.tr("Localizable", "data.shared.title")
    }
  }

  internal enum DataPrivacy {
    internal enum Info {
      /// Please enter your contact data in the next step.\n\nYour data will be encrypted. Only a health department can decrypt it during contact tracing.
      internal static let description = L10n.tr("Localizable", "dataPrivacy.info.description")
      /// Your contact data
      internal static let title = L10n.tr("Localizable", "dataPrivacy.info.title")
    }
  }

  internal enum DataRelease {
    internal enum Tan {
      /// TAN
      internal static let title = L10n.tr("Localizable", "dataRelease.tan.title")
      internal enum Failure {
        /// The TAN could not be loaded: %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dataRelease.tan.failure.message", String(describing: p1))
        }
      }
    }
  }

  internal enum Done {
    /// You can now share your encrypted contact data by presenting your QR code or by scanning a code from a place that uses luca.\n\nChecking in is possible at places that use luca or private meetings with other luca App users.
    internal static let description = L10n.tr("Localizable", "done.description")
  }

  internal enum Error {
    internal enum DeleteUser {
      /// Your account has already been deleted.\n\nYou can now register again.
      internal static let alreadyDeleted = L10n.tr("Localizable", "error.deleteUser.alreadyDeleted")
      /// Your account could not be deleted. (400 - Bad Request Error)\n\nPlease contact our support.
      internal static let badInput = L10n.tr("Localizable", "error.deleteUser.badInput")
      /// Your account could not be deleted. (403 - Forbidden Error)\n\nPlease contact our support.
      internal static let invalidSignature = L10n.tr("Localizable", "error.deleteUser.invalidSignature")
      /// Your account could not be deleted.\n\nPlease try again.
      internal static let rateLimit = L10n.tr("Localizable", "error.deleteUser.rateLimit")
      /// Your account could not be deleted.\n\nPlease contact our support.
      internal static let unableToBuildPayload = L10n.tr("Localizable", "error.deleteUser.unableToBuildPayload")
      /// Your account does not exist.\n\nYou can now register again.
      internal static let userNotFound = L10n.tr("Localizable", "error.deleteUser.userNotFound")
    }
    internal enum Network {
      /// The luca Service is currently unavailable, please try again later.
      internal static let badGateway = L10n.tr("Localizable", "error.network.badGateway")
    }
  }

  internal enum FetchTraceId {
    internal enum Failure {
      /// Error while checking the user status: %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "fetchTraceId.failure.message", String(describing: p1))
      }
    }
  }

  internal enum FormViewController {
    internal enum PhoneVerificationFailure {
      /// Please enter a new phone number.
      internal static let message = L10n.tr("Localizable", "formViewController.phoneVerificationFailure.message")
      /// Phone number verification failed
      internal static let title = L10n.tr("Localizable", "formViewController.phoneVerificationFailure.title")
    }
    internal enum UserDataFailure {
      internal enum Failed {
        /// User could not be registered: %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "formViewController.userDataFailure.failed.message", String(describing: p1))
        }
      }
      internal enum Unavailable {
        /// User data is not available
        internal static let message = L10n.tr("Localizable", "formViewController.userDataFailure.unavailable.message")
      }
    }
  }

  internal enum General {
    /// Privacy policy
    internal static let dataPrivacy = L10n.tr("Localizable", "general.dataPrivacy")
    /// FAQ
    internal static let faq = L10n.tr("Localizable", "general.faq")
    /// Key for health departments
    internal static let healthDepartmentKey = L10n.tr("Localizable", "general.healthDepartmentKey")
    /// Imprint
    internal static let imprint = L10n.tr("Localizable", "general.imprint")
    /// https://www.luca-app.de/impressum/
    internal static let linkImprint = L10n.tr("Localizable", "general.linkImprint")
    /// Support
    internal static let support = L10n.tr("Localizable", "general.support")
    /// Terms of use
    internal static let termsAndConditions = L10n.tr("Localizable", "general.termsAndConditions")
    /// luca
    internal static let title = L10n.tr("Localizable", "general.title")
    internal enum Failure {
      internal enum InvalidCertificate {
        /// When attempting to establish a secure connection to the luca servers, we found untrusted certificates.\n\nPlease try switching your network and make sure that you're using the latest app version.
        internal static let message = L10n.tr("Localizable", "general.failure.invalidCertificate.message")
        /// Unexpected server certificates
        internal static let title = L10n.tr("Localizable", "general.failure.invalidCertificate.title")
      }
      internal enum NoInternet {
        /// No internet connection could be made.
        internal static let message = L10n.tr("Localizable", "general.failure.noInternet.message")
      }
      internal enum Unknown {
        /// Unknown error: %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "general.failure.unknown.message", String(describing: p1))
        }
      }
    }
    internal enum Greeting {
      /// Hello!
      internal static let title = L10n.tr("Localizable", "general.greeting.title")
    }
    internal enum Support {
      /// hello@luca-app.de
      internal static let email = L10n.tr("Localizable", "general.support.email")
      /// It is not possible to send an email from this device because no email account is connected.
      internal static let error = L10n.tr("Localizable", "general.support.error")
      internal enum Email {
        /// Dear luca support,<br><br>The following problem occurred while using the app:<br><br><i>Please describe your problem and where it occurs, as precisely as possible. It would also be very helpful if you could attach a screenshot or screen capture of your problem or error message.</i><br><br><br>Device: %@<br>Operating system: iOS %@<br>App version: %@
        internal static func body(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
          return L10n.tr("Localizable", "general.support.email.body", String(describing: p1), String(describing: p2), String(describing: p3))
        }
      }
    }
  }

  internal enum History {
    internal enum Accessibility {
      /// View data accesses
      internal static let dataAccessButton = L10n.tr("Localizable", "history.accessibility.dataAccessButton")
    }
    internal enum Alert {
      /// Would you like to share your contact data and the last %@ days of your history with the health department? This is only done with your voluntary consent in accordance with art. 9 (2) a) GDPR (more: %@).
      internal static func description(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "history.alert.description", String(describing: p1), String(describing: p2))
      }
      /// data privacy - app
      internal static let link = L10n.tr("Localizable", "history.alert.link")
      /// Confirm share
      internal static let title = L10n.tr("Localizable", "history.alert.title")
      internal enum Description {
        /// Would you like to share your contact data and the last 14 days of your history with the health department? This is only done with your voluntary consent under article 9 (2) a) GDPR (more: %@).
        internal static func accessibility(_ p1: Any) -> String {
          return L10n.tr("Localizable", "history.alert.description.accessibility", String(describing: p1))
        }
      }
    }
    internal enum Checkin {
      internal enum Checkout {
        /// %@ to %@
        internal static func time(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "history.checkin.checkout.time", String(describing: p1), String(describing: p2))
        }
      }
    }
    internal enum Data {
      /// Shared data
      internal static let shared = L10n.tr("Localizable", "history.data.shared")
      /// Updated data
      internal static let updated = L10n.tr("Localizable", "history.data.updated")
    }
    internal enum DataAccess {
      /// %@ data requests
      internal static func count(_ p1: Any) -> String {
        return L10n.tr("Localizable", "history.dataAccess.count", String(describing: p1))
      }
    }
  }

  internal enum LocationCheckinViewController {
    /// Automatic checkout
    internal static let autoCheckout = L10n.tr("Localizable", "locationCheckinViewController.autoCheckout")
    /// You're checked in!
    internal static let welcomeMessage = L10n.tr("Localizable", "locationCheckinViewController.welcomeMessage")
    internal enum Accessibility {
      /// Checkout
      internal static let checkoutSlider = L10n.tr("Localizable", "locationCheckinViewController.accessibility.checkoutSlider")
      /// Checkout of location
      internal static let directCheckout = L10n.tr("Localizable", "locationCheckinViewController.accessibility.directCheckout")
    }
    internal enum AutoCheckout {
      /// Off
      internal static let off = L10n.tr("Localizable", "locationCheckinViewController.autoCheckout.off")
      /// On
      internal static let on = L10n.tr("Localizable", "locationCheckinViewController.autoCheckout.on")
      internal enum Permission {
        internal enum BeforePrompt {
          /// data privacy - app
          internal static let link = L10n.tr("Localizable", "locationCheckinViewController.autoCheckout.permission.beforePrompt.link")
          /// This automatic checkout feature uses geofencing. If a luca-location uses it as well, you can check out automatically using your location through the GPS function of your phone, even when the app is closed. This is only done with your consent under art. 6 (1) 1 a) GDPR (more: %@). However, you can still check out manually at any time.
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "locationCheckinViewController.autoCheckout.permission.beforePrompt.message", String(describing: p1))
          }
          /// OKAY
          internal static let okButton = L10n.tr("Localizable", "locationCheckinViewController.autoCheckout.permission.beforePrompt.okButton")
          /// Automatic checkout
          internal static let title = L10n.tr("Localizable", "locationCheckinViewController.autoCheckout.permission.beforePrompt.title")
        }
      }
    }
    internal enum AutoCheckoutPermissionDisabled {
      /// Change your luca location permission to "Always".
      internal static let message = L10n.tr("Localizable", "locationCheckinViewController.autoCheckoutPermissionDisabled.message")
      /// Auto-checkout is not possible
      internal static let title = L10n.tr("Localizable", "locationCheckinViewController.autoCheckoutPermissionDisabled.title")
    }
    internal enum CheckOutFailed {
      internal enum General {
        /// There was an error while checking out: %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "locationCheckinViewController.checkOutFailed.general.message", String(describing: p1))
        }
      }
      internal enum LocationNotAvailable {
        /// There is no information available about the current location.
        internal static let message = L10n.tr("Localizable", "locationCheckinViewController.checkOutFailed.locationNotAvailable.message")
      }
      internal enum LowDuration {
        /// You just checked in! You can first check out when you've stayed a bit longer.
        internal static let message = L10n.tr("Localizable", "locationCheckinViewController.checkOutFailed.lowDuration.message")
      }
      internal enum StillInLocation {
        /// You are still at %@. Move farther away to check out.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "locationCheckinViewController.checkOutFailed.stillInLocation.message", String(describing: p1))
        }
        /// You are still at the location. Move farther away to check out.
        internal static let messageWithoutName = L10n.tr("Localizable", "locationCheckinViewController.checkOutFailed.stillInLocation.messageWithoutName")
        /// Info
        internal static let title = L10n.tr("Localizable", "locationCheckinViewController.checkOutFailed.stillInLocation.title")
      }
    }
    internal enum LocationInfoFetchFailure {
      /// Error while loading the location data: %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "locationCheckinViewController.locationInfoFetchFailure.message", String(describing: p1))
      }
    }
    internal enum Permission {
      internal enum Change {
        /// To use auto-checkout you must choose the option "Always" in your luca location settings.
        internal static let message = L10n.tr("Localizable", "locationCheckinViewController.permission.change.message")
        /// Location Settings
        internal static let title = L10n.tr("Localizable", "locationCheckinViewController.permission.change.title")
      }
      internal enum Denied {
        /// Your location setting has still not been enabled. Without your position we cannot check if you have left %@.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "locationCheckinViewController.permission.denied.message", String(describing: p1))
        }
        /// Your location setting has still not been enabled. Without your position we cannot check if you have left the location.
        internal static let messageWithoutName = L10n.tr("Localizable", "locationCheckinViewController.permission.denied.messageWithoutName")
      }
    }
  }

  internal enum MainTabBarViewController {
    internal enum ScannerFailure {
      /// Error: %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "mainTabBarViewController.scannerFailure.message", String(describing: p1))
      }
      /// Scanner error
      internal static let title = L10n.tr("Localizable", "mainTabBarViewController.scannerFailure.title")
    }
    internal enum UserRegistrationFailure {
      internal enum General {
        /// User could not be registered: %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "mainTabBarViewController.userRegistrationFailure.general.message", String(describing: p1))
        }
      }
      internal enum NoInternet {
        /// User could not be registered! No internet connection could be made.
        internal static let message = L10n.tr("Localizable", "mainTabBarViewController.userRegistrationFailure.noInternet.message")
      }
    }
  }

  internal enum My {
    internal enum Luca {
      /// Calendar
      internal static let calendar = L10n.tr("Localizable", "my.luca.calendar")
      /// My luca
      internal static let title = L10n.tr("Localizable", "my.luca.title")
    }
  }

  internal enum Navigation {
    internal enum Basic {
      /// AGREE
      internal static let agree = L10n.tr("Localizable", "navigation.basic.agree")
      /// Attention!
      internal static let attention = L10n.tr("Localizable", "navigation.basic.attention")
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "navigation.basic.cancel")
      /// DONE
      internal static let done = L10n.tr("Localizable", "navigation.basic.done")
      /// Error
      internal static let error = L10n.tr("Localizable", "navigation.basic.error")
      /// Attention
      internal static let hint = L10n.tr("Localizable", "navigation.basic.hint")
      /// NEXT
      internal static let next = L10n.tr("Localizable", "navigation.basic.next")
      /// No
      internal static let no = L10n.tr("Localizable", "navigation.basic.no")
      /// Ok
      internal static let ok = L10n.tr("Localizable", "navigation.basic.ok")
      /// Start
      internal static let start = L10n.tr("Localizable", "navigation.basic.start")
      /// Yes
      internal static let yes = L10n.tr("Localizable", "navigation.basic.yes")
    }
    internal enum Tab {
      /// Account
      internal static let account = L10n.tr("Localizable", "navigation.tab.account")
      /// Check in
      internal static let checkin = L10n.tr("Localizable", "navigation.tab.checkin")
      /// My luca
      internal static let health = L10n.tr("Localizable", "navigation.tab.health")
      /// History
      internal static let history = L10n.tr("Localizable", "navigation.tab.history")
    }
  }

  internal enum Notification {
    internal enum Checkout {
      /// Don't forget to checkout in the luca app when you've left your location.
      internal static let description = L10n.tr("Localizable", "notification.checkout.description")
      /// Important!
      internal static let title = L10n.tr("Localizable", "notification.checkout.title")
    }
    internal enum Permission {
      /// You didn't allow notifications. Please enable luca notifications in your settings to be reminded to checkout.
      internal static let description = L10n.tr("Localizable", "notification.permission.description")
      /// Enable notifications
      internal static let title = L10n.tr("Localizable", "notification.permission.title")
    }
  }

  internal enum PhoneNumber {
    internal enum Confirmation {
      internal enum Description {
        /// You will receive a call with a message containing the TAN that is needed to verify your phone number in the next step. Please make sure the phone is nearby and the number is correct:
        internal static let fixed = L10n.tr("Localizable", "phoneNumber.confirmation.description.fixed")
        /// To verify your phone number we will send a TAN to the number you provided in the next step. Please make sure this number is correct:
        internal static let mobile = L10n.tr("Localizable", "phoneNumber.confirmation.description.mobile")
      }
    }
  }

  internal enum Private {
    internal enum Meeting {
      /// Let your guests scan the QR code to check into your meeting.
      internal static let description = L10n.tr("Localizable", "private.meeting.description")
      internal enum Accessibility {
        /// End meeting
        internal static let endMeeting = L10n.tr("Localizable", "private.meeting.accessibility.endMeeting")
        /// Guests: %d out of %d
        internal static func guests(_ p1: Int, _ p2: Int) -> String {
          return L10n.tr("Localizable", "private.meeting.accessibility.guests", p1, p2)
        }
        /// Length: %@
        internal static func length(_ p1: Any) -> String {
          return L10n.tr("Localizable", "private.meeting.accessibility.length", String(describing: p1))
        }
      }
      internal enum Alert {
        /// When you check yourself in at a private meeting, your host can see your first and last name.\n\nPrivate meetings are used as reminders and won't be shared with health authorities.
        internal static let description = L10n.tr("Localizable", "private.meeting.alert.description")
      }
      internal enum Create {
        /// There was an error while creating a new meeting: %@
        internal static func failure(_ p1: Any) -> String {
          return L10n.tr("Localizable", "private.meeting.create.failure", String(describing: p1))
        }
      }
      internal enum End {
        /// Do you really want to end this meeting?
        internal static let description = L10n.tr("Localizable", "private.meeting.end.description")
        /// There was an error while ending the meeting: %@
        internal static func failure(_ p1: Any) -> String {
          return L10n.tr("Localizable", "private.meeting.end.failure", String(describing: p1))
        }
        /// End meeting
        internal static let title = L10n.tr("Localizable", "private.meeting.end.title")
      }
      internal enum Info {
        /// When friends and family check into your private meeting, their first and last names will be shown in your app.\n\nThey will also see your first and last name in their app.\n\nYou can already use this feature at locations that are not part of the luca system to keep track of private meetings yourself.
        internal static let description = L10n.tr("Localizable", "private.meeting.info.description")
        /// Private Meeting
        internal static let title = L10n.tr("Localizable", "private.meeting.info.title")
      }
      internal enum Participants {
        /// No participants.
        internal static let `none` = L10n.tr("Localizable", "private.meeting.participants.none")
        /// Participants
        internal static let title = L10n.tr("Localizable", "private.meeting.participants.title")
      }
      internal enum Start {
        /// Do you want to start a private meeting now?\n\nWhen friends and family check into your private meeting, their first and last names will be shown in your app. They will also see your first and last name in their app.\n\nPrivate meetings are used as reminders and won't be shared with health authorities.
        internal static let description = L10n.tr("Localizable", "private.meeting.start.description")
        /// Set up a private meeting
        internal static let title = L10n.tr("Localizable", "private.meeting.start.title")
      }
    }
  }

  internal enum QrCodeGeneration {
    internal enum Failure {
      /// QR Code could not be generated: %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "qrCodeGeneration.failure.message", String(describing: p1))
      }
    }
  }

  internal enum Terms {
    internal enum Acceptance {
      /// We are updating our terms of use and privacy policy.
      internal static let description = L10n.tr("Localizable", "terms.acceptance.description")
      /// https://www.luca-app.de/changes-terms-of-use-app/
      internal static let linkChanges = L10n.tr("Localizable", "terms.acceptance.linkChanges")
      /// Tap "AGREE" to accept the updated terms of use and privacy policy.
      internal static let linkDescription = L10n.tr("Localizable", "terms.acceptance.linkDescription")
      /// Changes
      internal static let termsAndConditionsChanges = L10n.tr("Localizable", "terms.acceptance.termsAndConditionsChanges")
    }
  }

  internal enum Test {
    internal enum Add {
      /// Add document
      internal static let title = L10n.tr("Localizable", "test.add.title")
    }
    internal enum Delete {
      /// Do you really want to delete this document?
      internal static let description = L10n.tr("Localizable", "test.delete.description")
      /// Delete document
      internal static let title = L10n.tr("Localizable", "test.delete.title")
    }
    internal enum Expiry {
      /// h
      internal static let hours = L10n.tr("Localizable", "test.expiry.hours")
      /// m
      internal static let minutes = L10n.tr("Localizable", "test.expiry.minutes")
    }
    internal enum Result {
      /// dd.MM.yyyy
      internal static let dateFormat = L10n.tr("Localizable", "test.result.dateFormat")
      /// Expiry: %@
      internal static func expiry(_ p1: Any) -> String {
        return L10n.tr("Localizable", "test.result.expiry", String(describing: p1))
      }
      /// Rapid test
      internal static let fast = L10n.tr("Localizable", "test.result.fast")
      /// Testresult: Negative
      internal static let negative = L10n.tr("Localizable", "test.result.negative")
      /// Other
      internal static let other = L10n.tr("Localizable", "test.result.other")
      /// PCR test
      internal static let pcr = L10n.tr("Localizable", "test.result.pcr")
      /// Testresult: Positive
      internal static let positive = L10n.tr("Localizable", "test.result.positive")
      /// Successful
      internal static let success = L10n.tr("Localizable", "test.result.success")
      internal enum Delete {
        /// It was not possible to delete this test.
        internal static let error = L10n.tr("Localizable", "test.result.delete.error")
      }
      internal enum Duration {
        /// one hour
        internal static let hour = L10n.tr("Localizable", "test.result.duration.hour")
        /// %i hours
        internal static func hours(_ p1: Int) -> String {
          return L10n.tr("Localizable", "test.result.duration.hours", p1)
        }
        /// %i minutes
        internal static func minutes(_ p1: Int) -> String {
          return L10n.tr("Localizable", "test.result.duration.minutes", p1)
        }
      }
      internal enum Error {
        /// The Document could not be imported
        internal static let title = L10n.tr("Localizable", "test.result.error.title")
      }
      internal enum Expiration {
        /// Unfortunately, the document cannot be imported because it already expired.
        internal static let error = L10n.tr("Localizable", "test.result.expiration.error")
      }
      internal enum Name {
        internal enum Validation {
          /// It was not possible to validate your name. Please check if your name is entered correctly in the app.
          internal static let error = L10n.tr("Localizable", "test.result.name.validation.error")
        }
      }
      internal enum Parsing {
        /// Data couldn't be processed.
        internal static let error = L10n.tr("Localizable", "test.result.parsing.error")
        /// Your document was added successfully.
        internal static let success = L10n.tr("Localizable", "test.result.parsing.success")
      }
      internal enum Positive {
        /// Not possible to add test\n\nluca helps you to check in easily. Since only negative test results are relevant for checking in, you can only add negative results at the moment.
        internal static let error = L10n.tr("Localizable", "test.result.positive.error")
      }
      internal enum Validation {
        /// It was not possible to validate that this document belongs to you. Please check if your name is entered correctly in the app.
        internal static let error = L10n.tr("Localizable", "test.result.validation.error")
      }
      internal enum Verification {
        /// Unfortunately, the document cannot be imported because the signature is not valid.
        internal static let error = L10n.tr("Localizable", "test.result.verification.error")
      }
    }
    internal enum Scanner {
      /// QR code scanner
      internal static let camera = L10n.tr("Localizable", "test.scanner.camera")
      /// Close
      internal static let close = L10n.tr("Localizable", "test.scanner.close")
      internal enum WrongScanner {
        /// This scanner is only for adding documents. If you want to check in at a location, switch to the "Check in" tab (bottom left of the navigation bar). There you will find the "Self check-in" button.
        internal static let description = L10n.tr("Localizable", "test.scanner.wrongScanner.description")
        /// You cannot check in here
        internal static let title = L10n.tr("Localizable", "test.scanner.wrongScanner.title")
      }
    }
    internal enum Uniqueness {
      internal enum Create {
        internal enum RandomTag {
          /// Failed to create a random tag.
          internal static let error = L10n.tr("Localizable", "test.uniqueness.create.randomTag.error")
        }
      }
      internal enum Encoding {
        /// Failed to encode test data.
        internal static let error = L10n.tr("Localizable", "test.uniqueness.encoding.error")
      }
      internal enum Rate {
        internal enum Limit {
          /// The rate limit has been reached.
          internal static let error = L10n.tr("Localizable", "test.uniqueness.rate.limit.error")
        }
      }
      internal enum Redeemed {
        /// This document was already imported.
        internal static let error = L10n.tr("Localizable", "test.uniqueness.redeemed.error")
      }
      internal enum Release {
        /// Document could not be deleted.
        internal static let error = L10n.tr("Localizable", "test.uniqueness.release.error")
      }
    }
  }

  internal enum Tests {
    internal enum Uniqueness {
      internal enum Consent {
        /// I hereby declare my consent in accordance with Art. 9 (2) a) in conjunction with Art. 6 (1) 1 a) DSGVO (more: %@) to the transmission of a pseudonymized identifier during the local storage of my COVID test, recovery or vaccination certificate in the luca app. This is solely to prevent document misuse so that multiple people cannot import and use the same document. The identifier of the recovery or vaccination document can be deleted by deleting the document in the app.
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Localizable", "tests.uniqueness.consent.description", String(describing: p1))
        }
        /// DSGVO
        internal static let title = L10n.tr("Localizable", "tests.uniqueness.consent.title")
        internal enum Title {
          /// D.S.G.V.O
          internal static let accessibility = L10n.tr("Localizable", "tests.uniqueness.consent.title.accessibility")
        }
      }
    }
  }

  internal enum UserData {
    /// You have given no address in your data yet. Please fill it before further usage.
    internal static let addressNotFilledMessage = L10n.tr("Localizable", "userData.addressNotFilledMessage")
    internal enum Address {
      /// Hosts usually have to collect the addresses of their guests. Therefore, in order to use luca, it's mandatory to provide your address.\n\nFields marked with * are mandatory.
      internal static let mandatory = L10n.tr("Localizable", "userData.address.mandatory")
    }
    internal enum Form {
      /// Please fill out all mandatory fields to continue
      internal static let accessibilityError = L10n.tr("Localizable", "userData.form.accessibilityError")
      /// * City
      internal static let city = L10n.tr("Localizable", "userData.form.city")
      /// Email
      internal static let email = L10n.tr("Localizable", "userData.form.email")
      /// * First name
      internal static let firstName = L10n.tr("Localizable", "userData.form.firstName")
      /// * Number
      internal static let houseNumber = L10n.tr("Localizable", "userData.form.houseNumber")
      /// * Last name
      internal static let lastName = L10n.tr("Localizable", "userData.form.lastName")
      /// * Phone number
      internal static let phoneNumber = L10n.tr("Localizable", "userData.form.phoneNumber")
      /// * Post code
      internal static let postCode = L10n.tr("Localizable", "userData.form.postCode")
      /// * Street
      internal static let street = L10n.tr("Localizable", "userData.form.street")
      internal enum Address {
        /// Where do you live?
        internal static let formTitle = L10n.tr("Localizable", "userData.form.address.formTitle")
      }
      internal enum City {
        /// Please enter your city to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.city.accessibilityError")
      }
      internal enum Field {
        /// This field is mandatory.
        internal static let error = L10n.tr("Localizable", "userData.form.field.error")
      }
      internal enum FirstName {
        /// Please enter your first name to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.firstName.accessibilityError")
      }
      internal enum HouseNumber {
        /// Please enter your house number to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.houseNumber.accessibilityError")
      }
      internal enum LastName {
        /// Please enter your last name to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.lastName.accessibilityError")
      }
      internal enum Name {
        /// What's your name?
        internal static let formTitle = L10n.tr("Localizable", "userData.form.name.formTitle")
      }
      internal enum Phone {
        /// How can you be contacted?
        internal static let formTitle = L10n.tr("Localizable", "userData.form.phone.formTitle")
      }
      internal enum PhoneNumber {
        /// Please enter your phone number to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.phoneNumber.accessibilityError")
      }
      internal enum PostCode {
        /// Please enter your zip code to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.postCode.accessibilityError")
      }
      internal enum Street {
        /// Please enter your street to continue.
        internal static let accessibilityError = L10n.tr("Localizable", "userData.form.street.accessibilityError")
      }
    }
    internal enum Name {
      /// Fields marked with * are mandatory.
      internal static let mandatory = L10n.tr("Localizable", "userData.name.mandatory")
    }
    internal enum Navigation {
      /// Edit contact data
      internal static let edit = L10n.tr("Localizable", "userData.navigation.edit")
    }
    internal enum Phone {
      /// Please provide a correct mobile or landline number. This number will be used for verification. You can choose if you want to provide an email address.\n\nFields marked with * are mandatory.
      internal static let mandatory = L10n.tr("Localizable", "userData.phone.mandatory")
    }
  }

  internal enum Vaccine {
    internal enum Result {
      /// Complete vaccination (%i/%i)
      internal static func complete(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "vaccine.result.complete", p1, p2)
      }
      /// BioNTech/Pfizer
      internal static let cormirnaty = L10n.tr("Localizable", "vaccine.result.cormirnaty")
      /// Vaccination
      internal static let `default` = L10n.tr("Localizable", "vaccine.result.default")
      /// %i. vaccination:
      internal static func description(_ p1: Int) -> String {
        return L10n.tr("Localizable", "vaccine.result.description", p1)
      }
      /// Johnson & Johnson
      internal static let janssen = L10n.tr("Localizable", "vaccine.result.janssen")
      /// Moderna
      internal static let moderna = L10n.tr("Localizable", "vaccine.result.moderna")
      /// Partial vaccination (%i/%i)
      internal static func partially(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "vaccine.result.partially", p1, p2)
      }
      /// Sputnik V
      internal static let sputnikV = L10n.tr("Localizable", "vaccine.result.sputnikV")
      /// AstraZeneca
      internal static let vaxzevria = L10n.tr("Localizable", "vaccine.result.vaxzevria")
    }
  }

  internal enum Verification {
    internal enum PhoneNumber {
      /// TAN
      internal static let code = L10n.tr("Localizable", "verification.phoneNumber.code")
      /// The TAN you entered was incorrect.
      internal static let failureMessage = L10n.tr("Localizable", "verification.phoneNumber.failureMessage")
      /// You have not verified your phone number yet. Please resave your contact data and verify your phone number.
      internal static let notYetVerified = L10n.tr("Localizable", "verification.phoneNumber.notYetVerified")
      /// No SMS could be sent out.
      internal static let requestFailure = L10n.tr("Localizable", "verification.phoneNumber.requestFailure")
      /// The verification was succesful.
      internal static let successMessage = L10n.tr("Localizable", "verification.phoneNumber.successMessage")
      /// Successful verification
      internal static let successTitle = L10n.tr("Localizable", "verification.phoneNumber.successTitle")
      /// Your data could not be saved.
      internal static let updateFailure = L10n.tr("Localizable", "verification.phoneNumber.updateFailure")
      /// The given phone number is not in the right format. Please enter a valid phone number and its country code (e.g. +49xxxxxxxxxxx).
      internal static let wrongFormat = L10n.tr("Localizable", "verification.phoneNumber.wrongFormat")
      internal enum Info {
        /// It can take a few minutes for the TAN to arrive. Please wait a moment before you request another TAN. If nothing happens after a few minutes, please check if you've provided the correct number and try again.
        internal static let message = L10n.tr("Localizable", "verification.phoneNumber.info.message")
        /// Info
        internal static let title = L10n.tr("Localizable", "verification.phoneNumber.info.title")
      }
      internal enum LimitReached {
        /// Your daily SMS limit has been reached, please try again later.
        internal static let message = L10n.tr("Localizable", "verification.phoneNumber.limitReached.message")
        /// Rate limit exceeded
        internal static let title = L10n.tr("Localizable", "verification.phoneNumber.limitReached.title")
      }
      internal enum TimerDelay {
        /// You have recently requested a TAN. Please wait a moment. If nothing happens, you can try again in:\n\n%@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "verification.phoneNumber.timerDelay.message", String(describing: p1))
        }
        /// TAN already requested
        internal static let title = L10n.tr("Localizable", "verification.phoneNumber.timerDelay.title")
        internal enum Message {
          /// You have recently requested a TAN. Please wait a moment. If nothing happens, you can try again in:\n\n%@ minutes, %@ seconds
          internal static func accessibility(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "verification.phoneNumber.timerDelay.message.accessibility", String(describing: p1), String(describing: p2))
          }
        }
      }
    }
  }

  internal enum VersionSupportChecker {
    /// Your luca version is not supported anymore! Please update your luca app in the AppStore.
    internal static let failureMessage = L10n.tr("Localizable", "versionSupportChecker.failureMessage")
  }

  internal enum Welcome {
    internal enum Checkboxes {
      /// Please accept the terms of use and agree to the privacy policy to continue.
      internal static let accessibilityError = L10n.tr("Localizable", "welcome.checkboxes.accessibilityError")
    }
    internal enum Info {
      /// luca helps you encrypt and securely submit your contact data. With luca, you don't have to worry about your data when visiting events, restaurants, cafés or bars anymore.
      internal static let description = L10n.tr("Localizable", "welcome.info.description")
    }
    internal enum PrivacyPolicy {
      internal enum Link {
        /// Privacy policy
        internal static let accessibility = L10n.tr("Localizable", "welcome.privacyPolicy.link.accessibility")
      }
    }
    internal enum TermsAndConditions {
      internal enum Link {
        /// Terms and Conditions
        internal static let accessibility = L10n.tr("Localizable", "welcome.termsAndConditions.link.accessibility")
      }
    }
  }

  internal enum WelcomeViewController {
    /// GitLab
    internal static let gitLab = L10n.tr("Localizable", "welcomeViewController.gitLab")
    /// https://www.luca-app.de/faq/
    internal static let linkFAQ = L10n.tr("Localizable", "welcomeViewController.linkFAQ")
    /// https://gitlab.com/lucaapp/ios
    internal static let linkGitLab = L10n.tr("Localizable", "welcomeViewController.linkGitLab")
    /// https://luca-app.de/app-privacy-policy/
    internal static let linkPrivacyPolicy = L10n.tr("Localizable", "welcomeViewController.linkPrivacyPolicy")
    /// https://luca-app.de/app-terms-and-conditions
    internal static let linkTC = L10n.tr("Localizable", "welcomeViewController.linkT_C")
    /// privacy policy
    internal static let termPrivacyPolicy = L10n.tr("Localizable", "welcomeViewController.termPrivacyPolicy")
    /// terms of use
    internal static let termTC = L10n.tr("Localizable", "welcomeViewController.termT_C")
    internal enum PrivacyPolicy {
      /// Privacy Policy Checkbox
      internal static let checkboxAccessibility = L10n.tr("Localizable", "welcomeViewController.privacyPolicy.checkboxAccessibility")
      /// I have read and agree to the privacy policy.
      internal static let checkboxMessage = L10n.tr("Localizable", "welcomeViewController.privacyPolicy.checkboxMessage")
      internal enum Checkbox {
        /// Confirmed: I have read and agree to the privacy policy. Double tap to unconfirm.
        internal static let confirmed = L10n.tr("Localizable", "welcomeViewController.privacyPolicy.checkbox.confirmed")
        /// Not confirmed: I have read and agree to the privacy policy. Double tap to confirm.
        internal static let notConfirmed = L10n.tr("Localizable", "welcomeViewController.privacyPolicy.checkbox.notConfirmed")
      }
    }
    internal enum TermsAndConditions {
      /// Terms of Use Checkbox
      internal static let checkboxAccessibility = L10n.tr("Localizable", "welcomeViewController.termsAndConditions.checkboxAccessibility")
      /// Not confirmed
      internal static let checkboxAccessibilityOff = L10n.tr("Localizable", "welcomeViewController.termsAndConditions.checkboxAccessibilityOff")
      /// Confirmed
      internal static let checkboxAccessibilityOn = L10n.tr("Localizable", "welcomeViewController.termsAndConditions.checkboxAccessibilityOn")
      /// I accept the terms of use.
      internal static let checkboxMessage = L10n.tr("Localizable", "welcomeViewController.termsAndConditions.checkboxMessage")
      internal enum Checkbox {
        /// Confirmed: I accept the terms of use. Double tap to unconfirm.
        internal static let confirmed = L10n.tr("Localizable", "welcomeViewController.termsAndConditions.checkbox.confirmed")
        /// Not confirmed: I accept the terms of use. Double tap to confirm.
        internal static let notConfirmed = L10n.tr("Localizable", "welcomeViewController.termsAndConditions.checkbox.notConfirmed")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
