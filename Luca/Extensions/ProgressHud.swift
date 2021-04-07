import Foundation
import JGProgressHUD

extension JGProgressHUD {
    static func lucaLoading() -> JGProgressHUD {
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Laden"
        hud.tintColor = .black
        return hud
    }
}
