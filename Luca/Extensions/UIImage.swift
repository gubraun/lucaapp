import UIKit

extension UIImage {
    
    // Referenced: https://stackoverflow.com/questions/33667481/add-a-line-as-a-selection-indicator-to-a-uitabbaritem-in-swift
    // Licensed under Creative Commons Attribution-ShareAlike; details see https://stackoverflow.com/help/licensing
    func createTabBarSelectionIndicator(tabSize: CGSize) -> UIImage? {
        let indicatorWidth: CGFloat = 80.0
        let indicatorHeight: CGFloat = 2.0
        UIGraphicsBeginImageContextWithOptions(tabSize, false, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(x: (tabSize.width - indicatorWidth) / 2.0, y: 0, width: indicatorWidth, height: indicatorHeight))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}
