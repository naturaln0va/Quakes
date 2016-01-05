
import UIKit
import CoreLocation


class RecentViewController: UIViewController
{
    
    @IBOutlet var countLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countLabel.text = "--"
        
        let status = CLLocationManager.authorizationStatus()
        if status != .AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        else if status == .AuthorizedWhenInUse {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
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
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        }
        else {
            countLabel.text = "No Location Access"
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            NetworkClient.sharedClient.getNearbyCount(lastLocation.coordinate.latitude,
                longitude: lastLocation.coordinate.longitude,
                radius: 450.0,
                completion: { count, error in
                    if let count = count where error == nil {
                        self.countLabel.text = "\(count)"
                    }
                }
            )
            manager.stopUpdatingLocation()
            manager.delegate = nil
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        countLabel.text = "Failed to get Location"
        manager.stopUpdatingLocation()
        manager.delegate = nil
    }
    
}
