
import UIKit

class StyledNavigationController: UINavigationController
{

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.shadowImage = UIImage()
        let navbarSzie = CGSize(width: navigationBar.frame.size.width, height: navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.height)
        navigationBar.setBackgroundImage(UIImage.imageOfColor(StyleController.mainAppColor, size: navbarSzie), for: .default)
        
        toolbar.tintColor = StyleController.contrastColor
        navigationBar.barTintColor = StyleController.mainAppColor
        navigationBar.tintColor = StyleController.contrastColor
        navigationBar.isTranslucent = false
        
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: StyleController.darkerMainAppColor,
            NSFontAttributeName: UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightMedium)
        ]
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

}
