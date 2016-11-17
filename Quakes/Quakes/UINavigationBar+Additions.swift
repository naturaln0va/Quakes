
import UIKit

extension UINavigationBar {
    
    func set(bottomDividerLineHidden hidden: Bool) {
        let image: UIImage? = hidden ? UIImage() : nil
        shadowImage = image
        setBackgroundImage(image, for: .default)
    }
    
}
