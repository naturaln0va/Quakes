
import UIKit
import CoreLocation

class EMSCLocationOperation: EMSCFetchQuakesOperation {

    let coordinate: CLLocationCoordinate2D
    let page: UInt
    
    init(page: UInt, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.page = page
    }
    
    override var urlString: String {
        // http://stackoverflow.com/questions/5217348/how-do-i-convert-kilometres-to-degrees-in-geodjango-geos
        // (n km / 40,000 km * 360 degrees)
        
        let radius = Double(SettingsController.sharedController.searchRadius.rawValue) / 40000.0 * 360.0
        let currentDate = NSDate()
        let currentCalendar = NSCalendar.currentCalendar()
        
        var dateParameterString = ""
        if let endDate = currentCalendar.dateByAddingUnit(.Month, value: -1 * Int(page), toDate: currentDate, options: [.MatchLast]), let startDate = currentCalendar.dateByAddingUnit(.Month, value: -1, toDate: endDate, options: [.MatchLast]) {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateParameterString = "&endtime=\(dateFormatter.stringFromDate(endDate))&starttime=\(dateFormatter.stringFromDate(startDate))"
        }
        
        return "\(baseURLString)query?limit=\(SettingsController.sharedController.fetchLimit.rawValue)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&maxradius=\(radius)&format=json" + dateParameterString
    }
    
}
