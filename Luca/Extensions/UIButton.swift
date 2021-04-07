import UIKit

extension UIButton {
    
    func leftIcon(image: UIImage?) {
        if let icon = image {
            self.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: icon.size.width)
            self.imageView?.contentMode = .scaleAspectFit
        }
    }
    
}
