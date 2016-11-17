
import UIKit

class StyledNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
