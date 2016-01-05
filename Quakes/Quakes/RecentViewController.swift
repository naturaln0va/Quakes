
import UIKit
import CoreLocation


class RecentViewController: UIViewController
{
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel!
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        return manager
    }()
    var currentLocation = CLLocation()
    var currentAddress: CLPlacemark?
    let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countLabel.text = ""
        infoLabel.text = ""
        activityIndicator.startAnimating()
        
        let status = CLLocationManager.authorizationStatus()
        if status != .AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        else if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}

extension RecentViewController: CLLocationManagerDelegate
{
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            countLabel.text = ""
            infoLabel.text = ""
            activityIndicator.startAnimating()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        }
        else {
            countLabel.text = "--"
            infoLabel.text = "Location access denied."
            activityIndicator.stopAnimating()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            NetworkClient.sharedClient.getNearbyCount(
                lastLocation.coordinate.latitude,
                longitude: lastLocation.coordinate.longitude,
                radius: 450.0,
                completion: { count, error in
                    if let count = count where error == nil {
                        self.countLabel.text = "\(count)"
                        self.activityIndicator.stopAnimating()
                        if self.infoLabel.text?.characters.count == 0 && self.currentAddress != nil {
                            self.infoLabel.text = "Earthquakes near \(self.currentAddress!.cityStateString())"
                        }
                    }
                }
            )
            
            geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in 
                if let placemark = place where error == nil && placemark.count > 0 {
                    if self.countLabel.text?.characters.count > 0 {
                        self.infoLabel.text = "Earthquakes near \(placemark[0].cityStateString())"
                    }
                    else {
                        self.currentAddress = placemark[0]
                    }
                }
            }
            
            currentLocation = lastLocation
            manager.stopUpdatingLocation()
            manager.delegate = nil
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        countLabel.text = "--"
        infoLabel.text = "Failed to find accurate location."
        manager.stopUpdatingLocation()
        manager.delegate = nil
    }
    
}
