
import CoreLocation

enum LocationHelperError: Error {
    case auth
    case location
    case placemark
}

protocol LocationHelperDelegate {
    func locationHelperRecievedLocation(location: CLLocation)
    func locationHelperRecievedPlacemark(placemark: CLPlacemark)
    func locationHelperFailedWithError(error: LocationHelperError)
}

class LocationHelper: NSObject {
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate let geocoder = CLGeocoder()
    
    var delegate: LocationHelperDelegate?
    var currentLocation: CLLocation?
    
    func startHelper() {
        let status = CLLocationManager.authorizationStatus()
        
        if CLLocationManager.locationServicesEnabled() && status == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        }
        else if status == .notDetermined {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            return
        }
        else {
            delegate?.locationHelperFailedWithError(error: LocationHelperError.auth)
        }
    }
    
    fileprivate func stopHelper() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
    
}

extension LocationHelper: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            startHelper()
        }
        else {
            stopHelper()
            delegate?.locationHelperFailedWithError(error: .auth)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }
        
        stopHelper()
        currentLocation = lastLocation
        
        NetworkUtility.networkOperationStarted()
        geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
            NetworkUtility.networkOperationFinished()
            
            if let placemark = place?.first, error == nil {
                self.delegate?.locationHelperRecievedPlacemark(placemark: placemark)
            }
            else {
                self.delegate?.locationHelperFailedWithError(error: .placemark)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        stopHelper()
        delegate?.locationHelperFailedWithError(error: .location)
    }
    
}
