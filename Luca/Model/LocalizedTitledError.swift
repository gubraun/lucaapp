import Foundation

/// Describes an error that provides localized messages describing why
/// an error occurred and provides more information about the error.
/// In addition it provides a title for an alert in case it would be shown to the user
protocol LocalizedTitledError: LocalizedError {

    /// Localized title of an alert
    var localizedTitle: String { get }
}
