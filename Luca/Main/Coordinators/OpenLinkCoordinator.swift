import UIKit

public class OpenLinkCoordinator: Coordinator {

    private let url: String

    public init(url: String) {
        self.url = url
    }

    public func start() {

        guard let url = URL(string: url) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }
}
