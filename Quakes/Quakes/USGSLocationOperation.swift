
import UIKit
import CoreLocation

class USGSLocationOperation: USGSFetchQuakesOperation {
    
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    override var urlString: String {
        return "\(baseURLString)query?format=geojson&latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&maxradiuskm=\(SettingsController.sharedController.searchRadius.rawValue)&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
    }
    
}
