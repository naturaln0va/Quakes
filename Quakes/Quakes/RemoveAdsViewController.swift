
import UIKit

class RemoveAdsViewController: UIViewController {

    @IBOutlet weak var removeAdsButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var confetti: SAConfettiView!
    
    fileprivate let helper = IAPUtility()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Remove Ads"
        messageLabel.text = ""
        
        if SettingsController.sharedController.hasSupported {
            headerLabel.text = "Thanks for your support ♥️"
            removeAdsButton.isHidden = true
            navigationItem.rightBarButtonItem = nil
            confetti.startConfetti()
        }
        else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(adRemovalPurchased),
                name: .didPurchaseProduct,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(adRemovalFailed),
                name: .didFailToPurchaseProduct,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(adRemovalCanceled),
                name: .didCancelPurchaseProduct,
                object: nil
            )

            removeAdsButton.setTitle("", for: UIControlState())
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .refresh,
                target: self,
                action: #selector(RemoveAdsViewController.refreshButtonPressed)
            )
            navigationItem.rightBarButtonItem?.isEnabled = false
            removeAdsButton.isEnabled = false
            
            loadingActivityIndicator.startAnimating()
            helper.requestProducts { products in
                self.loadingActivityIndicator.stopAnimating()

                if let firstProduct = products?.first, IAPUtility.isRemoveAdsProduct(firstProduct) {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .currency
                    
                    if let formattedNumberString = numberFormatter.string(from: firstProduct.price) {
                        self.removeAdsButton.titleLabel?.numberOfLines = 0
                        self.removeAdsButton.titleLabel?.textAlignment = .center
                        
                        self.removeAdsButton.setTitle("\(formattedNumberString)\nRemove Ads", for: UIControlState())
                    }
                    
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.removeAdsButton.isEnabled = true
                }
                else {
                    self.removeAdsButton.setTitle("Network Failure", for: UIControlState())
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.set(bottomDividerLineHidden: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        confetti.stopConfetti()
        navigationController?.navigationBar.set(bottomDividerLineHidden: false)
    }
    
    // MARK: Notifications
    @objc private func adRemovalPurchased() {
        headerLabel.text = "Thanks for your support ♥️"
        removeAdsButton.isHidden = true
        navigationItem.rightBarButtonItem = nil
        SettingsController.sharedController.hasSupported = true
        confetti.startConfetti()
    }
    
    @objc private func adRemovalFailed() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(RemoveAdsViewController.refreshButtonPressed)
        )
        
        messageLabel.alpha = 1.0
        messageLabel.text = "Ad removal failed."
        
        UIView.animate(withDuration: 0.3, delay: 4.0, options: [], animations: {
            self.messageLabel.alpha = 0.0
        }) { _ in
            self.messageLabel.text = ""
        }
    }
    
    @objc private func adRemovalCanceled() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(RemoveAdsViewController.refreshButtonPressed)
        )
        
        messageLabel.alpha = 1.0
        messageLabel.text = "Ad removal canceled."
        
        UIView.animate(withDuration: 0.3, delay: 4.0, options: [], animations: {
            self.messageLabel.alpha = 0.0
        }) { _ in
            self.messageLabel.text = ""
        }
    }
    
    // MARK: Actions
    @IBAction func removeAdsButtonPressed(_ sender: UIButton) {
        helper.purchaseRemoveAds()
    }
    
    @objc private func refreshButtonPressed() {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        activityView.startAnimating()
        
        helper.restorePurchases()
    }

}
