
import UIKit


class RemoveAdsViewController: UIViewController
{

    @IBOutlet weak var removeAdsButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    private let helper = IAPUtility()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Remove Ads"
        
        if SettingsController.sharedController.hasPaidToRemoveAds {
            headerLabel.text = "Thanks for your support ♥️"
            removeAdsButton.hidden = true
        }
        else {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "adRemovalPurchased",
                name: IAPUtility.IAPHelperPurchaseNotification,
                object: nil
            )
            
            removeAdsButton.setTitle("", forState: .Normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .Refresh,
                target: self,
                action: "refreshButtonPressed"
            )
            navigationItem.rightBarButtonItem?.enabled = false
            removeAdsButton.enabled = false
            
            loadingActivityIndicator.startAnimating()
            helper.requestProducts { products in
                self.loadingActivityIndicator.stopAnimating()

                if let firstProduct = products?.first where IAPUtility.isRemoveAdsProduct(firstProduct) {
                    let numberFormatter = NSNumberFormatter()
                    numberFormatter.numberStyle = .CurrencyStyle
                    
                    if let formattedNumberString = numberFormatter.stringFromNumber(firstProduct.price) {
                        self.removeAdsButton.titleLabel?.numberOfLines = 0
                        self.removeAdsButton.titleLabel?.textAlignment = .Center
                        
                        self.removeAdsButton.setTitle("\(formattedNumberString)\nRemove Ads", forState: .Normal)
                    }
                    
                    self.navigationItem.rightBarButtonItem?.enabled = true
                    self.removeAdsButton.enabled = true
                }
                else {
                    self.removeAdsButton.setTitle("Network Failure", forState: .Normal)
                }
            }
        }
    }
    
    // MARK: Notifications
    func adRemovalPurchased() {
        headerLabel.text = "Thanks for your support ♥️"
        removeAdsButton.hidden = true
        navigationItem.rightBarButtonItem = nil
        SettingsController.sharedController.hasPaidToRemoveAds = true
    }
    
    // MARK: Actions
    @IBAction func removeAdsButtonPressed(sender: UIButton) {
        helper.purchaseRemoveAds()
    }
    
    func refreshButtonPressed() {
        helper.restorePurchases()
    }

}
