
import UIKit
import CoreLocation

enum LocationOption: String {
    case Nearby
    case World
    case Major
}

protocol LocationFinderViewControllerDelegate {
    func locationFinderViewControllerDidSelectPlace(placemark: CLPlacemark)
    func locationFinderViewControllerDidSelectOption(option: LocationOption)
}

class LocationFinderViewController: UIViewController
{

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var filterSegment: UISegmentedControl!
    @IBOutlet weak var filterViewBottomConstraint: NSLayoutConstraint!
    
    let manager = CLLocationManager()
    var delegate: LocationFinderViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = StyleController.backgroundColor
        searchTextField.backgroundColor = StyleController.darkerMainAppColor
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        
        if let lastOption = SettingsController.sharedController.lastLocationOption {
            switch lastOption {
            case LocationOption.Nearby.rawValue:
                filterSegment.selectedSegmentIndex = 0
                
            case LocationOption.World.rawValue:
                filterSegment.selectedSegmentIndex = 1
                
            case LocationOption.Major.rawValue:
                filterSegment.selectedSegmentIndex = 2
                
            default:
                print("Unknown option from the SettingsController.")
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    private func dismiss() {
        view.endEditing(true)
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Notifications
    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        
        filterViewBottomConstraint.constant = keyboardHeight
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animateWithDuration(duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let userInfo = notification.userInfo!
        filterViewBottomConstraint.constant = 0.0
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animateWithDuration(duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    @IBAction func cancelButtonPressed(sender: UIButton) {
        dismiss()
    }
    
    @IBAction func filterSegmentWasChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            var errorMessage = ""
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedWhenInUse:
                if CLLocationManager.locationServicesEnabled() {
                    delegate?.locationFinderViewControllerDidSelectOption(.Nearby)
                }
                else {
                    errorMessage = "Location services are turned off"
                }
                break
            case .NotDetermined:
                manager.delegate = self
                manager.requestWhenInUseAuthorization()
                break
            default:
                errorMessage = "Location access is denied"
                break
            }
            
            if errorMessage.characters.count > 0 {
                sender.selectedSegmentIndex = -1

                let alertView = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .Alert)
                
                alertView.addAction(UIAlertAction(title: "Open Settings", style: .Default, handler: { action in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
                
                alertView.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                
                presentViewController(alertView, animated: true, completion: nil)
            }
        }
        else if sender.selectedSegmentIndex == 1 {
            delegate?.locationFinderViewControllerDidSelectOption(.World)
        }
        else if sender.selectedSegmentIndex == 2 {
            delegate?.locationFinderViewControllerDidSelectOption(.Major)
        }
    }
    
    func searchForAddressWithText(searchText: String) {
        let geocoder = CLGeocoder()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        geocoder.geocodeAddressString(searchText) { places, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let place = places?.first where error == nil {
                
                if places != nil {
                    for placeToLookInTo in places! {
                        print("\(placeToLookInTo)\n\n")
                    }
                }
                
                if let _ = place.location {
                    SettingsController.sharedController.lastSearchedPlace = place
                    self.delegate?.locationFinderViewControllerDidSelectPlace(place)
                }
                else {
                    //self.searchHelperLabel.text = self.searchErrorMessage + " \(searchText)"
                }
            }
            else {
                //self.searchHelperLabel.text = self.searchErrorMessage + " '\(searchText)'.\n\nTry again?"
            }
        }
    }

}

extension LocationFinderViewController: CLLocationManagerDelegate
{
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            delegate?.locationFinderViewControllerDidSelectOption(.Nearby)
        }
    }
    
}

extension LocationFinderViewController: UITextFieldDelegate
{
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
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
