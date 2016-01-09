
import UIKit
import CoreLocation

class LocationFinderViewController: UIViewController
{

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchHelperLabel: UILabel!
    
    let searchPromptMessage = "Choose a location to view recent earthquakes by.\n\nYou can search locations by:\n・Address\n・City\n・Zipcode\n・State or Country"
    let searchErrorMessage = "Sorry there does not seem to be a valid location for"
    var optionDelegate: OptionSelectionViewControllerDelegate!
    
    init(delegate: OptionSelectionViewControllerDelegate) {
        super.init(nibName: "LocationFinderViewController", bundle: nil)
        
        optionDelegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Enter a Location"
        view.backgroundColor = StyleController.backgroundColor
        
        searchTextField.delegate = self
        searchHelperLabel.text = searchPromptMessage
    }
    
    func searchForAddressWithText(searchText: String) {
        let geocoder = CLGeocoder()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        geocoder.geocodeAddressString(searchText) { places, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let place = places?.first where error == nil {
                if let _ = place.location {
                    SettingsController.sharedContoller.lastSearchedPlace = place
                    self.optionDelegate.optionSelectionViewControllerDidSelectPlace(place)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                else {
                    self.searchHelperLabel.text = self.searchErrorMessage + " \(searchText)"
                }
            }
            else {
                self.searchHelperLabel.text = self.searchErrorMessage + " '\(searchText)'.\n\nTry again?"
            }
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
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if searchHelperLabel.text != searchPromptMessage {
            searchHelperLabel.text = searchPromptMessage
        }
    }
    
}
