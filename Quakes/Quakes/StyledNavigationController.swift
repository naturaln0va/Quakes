
import UIKit

class StyledNavigationController: UINavigationController
{

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.shadowImage = UIImage()
        let navbarSzie = CGSize(width: navigationBar.frame.size.width, height: navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.height)
        navigationBar.setBackgroundImage(UIImage.imageOfColor(StyleController.mainAppColor, size: navbarSzie), forBarMetrics: .Default)
        
        navigationBar.barTintColor = StyleController.mainAppColor
        navigationBar.tintColor = StyleController.contrastColor
        navigationBar.translucent = false
        
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: StyleController.darkerMainAppColor,
            NSFontAttributeName: UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        ]
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }

}
