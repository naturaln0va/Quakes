
import UIKit
import CoreLocation

class EMSCLocationOperation: EMSCFetchQuakesOperation {

    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    override var urlString: String {
        // http://stackoverflow.com/questions/5217348/how-do-i-convert-kilometres-to-degrees-in-geodjango-geos
        // (n km / 40,000 km * 360 degrees)
        
        let radius = Double(SettingsController.sharedController.searchRadius.rawValue) / 40000.0 * 360.0
        return "\(baseURLString)query?limit=\(SettingsController.sharedController.fetchLimit.rawValue)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&maxradius=\(radius)&format=json"
    }
    
}
