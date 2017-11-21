
import UIKit

class StyledNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.tintColor = StyleController.contrastColor
        navigationBar.barTintColor = StyleController.mainAppColor
        navigationBar.tintColor = StyleController.contrastColor
        navigationBar.isTranslucent = false
        
        navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: StyleController.darkerMainAppColor,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
        ]
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

}
