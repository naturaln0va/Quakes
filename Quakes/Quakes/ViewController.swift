
import UIKit


class ViewController: UIViewController
{

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NetworkClient.sharedClient.getRecentQuakes()
        view.backgroundColor = UIColor.whiteColor()
    }
    
}

