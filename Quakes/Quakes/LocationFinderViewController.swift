
import UIKit
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


enum LocationOption: String {
    case Nearby
    case World
    case Major
}

protocol LocationFinderViewControllerDelegate: class {
    func locationFinderViewControllerDidSelectPlace(_ placemark: CLPlacemark)
    func locationFinderViewControllerDidSelectOption(_ option: LocationOption)
}

class LocationFinderViewController: UIViewController
{

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var filterSegment: UISegmentedControl!
    @IBOutlet weak var filterViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var filterSegmentTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var controlContainerView: UIView!
    
    fileprivate var shouldDismiss = false
    fileprivate let manager = CLLocationManager()
    weak var delegate: LocationFinderViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TelemetryController.sharedController.logQuakeFinderOpened()
        
        title = "Choose a Type"
        view.backgroundColor = UIColor.white
        searchTextField.backgroundColor = StyleController.searchBarColor
        controlContainerView.backgroundColor = StyleController.backgroundColor
        filterSegment.alpha = 0
        
        controlContainerView.isHidden = SettingsController.sharedController.hasSearchedBefore()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(LocationFinderViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(LocationFinderViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        searchTextField.delegate = self
        searchTextField.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    fileprivate func dismiss() {
        view.endEditing(true)
        shouldDismiss = true
    }
    
    // MARK: Notifications
    func keyboardWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        
        filterViewBottomConstraint.constant = keyboardHeight
        filterSegmentTopConstraint.constant = 15
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
            self.filterSegment.alpha = 1
        }) 
    }
    
    func keyboardWillHide(_ notification: Notification) {
        let userInfo = notification.userInfo!
        
        filterViewBottomConstraint.constant = 0.0
        filterSegmentTopConstraint.constant = -35
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
            self.filterSegment.alpha = 0
        }, completion: { _ in
            if self.shouldDismiss { self.presentingViewController?.dismiss(animated: true, completion: nil) }
        })
    }
    
    // MARK: - Actions
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss()
    }
    
    @IBAction func filterSegmentWasChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            var errorMessage = ""
            switch CLLocationManager.authorizationStatus() {
            case .authorizedWhenInUse:
                if CLLocationManager.locationServicesEnabled() {
                    delegate?.locationFinderViewControllerDidSelectOption(.Nearby)
                }
                else {
                    errorMessage = "Location services are turned off."
                }
                break
            case .notDetermined:
                manager.delegate = self
                manager.requestWhenInUseAuthorization()
                break
            default:
                errorMessage = "Please enable location access to view nearby quakes."
                break
            }
            
            if errorMessage.characters.count > 0 {
                sender.selectedSegmentIndex = -1

                let alertView = UIAlertController(title: "Permission Needed", message: errorMessage, preferredStyle: .alert)
                
                alertView.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { action in
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }))
                
                alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                present(alertView, animated: true, completion: nil)
            }
        }
        else if sender.selectedSegmentIndex == 1 {
            delegate?.locationFinderViewControllerDidSelectOption(.World)
        }
        else if sender.selectedSegmentIndex == 2 {
            delegate?.locationFinderViewControllerDidSelectOption(.Major)
        }
    }
    
    func searchForAddressWithText(_ searchText: String) {
        let geocoder = CLGeocoder()
        
        NetworkUtility.networkOperationStarted()
        geocoder.geocodeAddressString(searchText) { places, error in
            NetworkUtility.networkOperationFinished()
            if let place = places?.first, error == nil {
                
                if let _ = place.location {
                    DispatchQueue.main.async {
                        self.delegate?.locationFinderViewControllerDidSelectPlace(place)
                    }
                }
                else {
                    self.searchTextField.text = "Invalid Location"
                }
            }
            else {
                self.searchTextField.text = "Invalid Location"
            }
        }
    }

}

extension LocationFinderViewController: CLLocationManagerDelegate
{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            delegate?.locationFinderViewControllerDidSelectOption(.Nearby)
        }
        else {
            filterSegment.selectedSegmentIndex = -1
        }
    }
    
}

extension LocationFinderViewController: UITextFieldDelegate
{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text?.characters.count > 0 {
            searchForAddressWithText(textField.text!)
            textField.resignFirstResponder()
            return true
        }
        else {
            return false
        }
    }
    
}
