
import UIKit

class RemoveAdsViewController: UIViewController
{

    @IBOutlet weak var removeAdsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Remove Ads"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Refresh,
            target: self,
            action: "refreshButtonPressed"
        )
    }
    
    // MARK: - Actions
    @IBAction func removeAdsButtonPressed(sender: UIButton) {
        print("Removing ads")
    }
    
    func refreshButtonPressed() {
        print("Refreshing")
    }

}
