
import UIKit
import CoreLocation

class USGSLocationOperation: USGSFetchQuakesOperation {
    
    let coordinate: CLLocationCoordinate2D
    let page: UInt
    
    init(page: UInt, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.page = page
    }
    
    override var urlString: String {
        let currentDate = NSDate()
        let currentCalendar = NSCalendar.currentCalendar()
        
        var dateParameterString = ""
        if let endDate = currentCalendar.dateByAddingUnit(.Month, value: -1 * Int(page), toDate: currentDate, options: [.MatchLast]), let startDate = currentCalendar.dateByAddingUnit(.Month, value: -1, toDate: endDate, options: [.MatchLast]) {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateParameterString = "&endtime=\(dateFormatter.stringFromDate(endDate))&starttime=\(dateFormatter.stringFromDate(startDate))"
        }
        
        return "\(baseURLString)query?format=geojson&latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&maxradiuskm=\(SettingsController.sharedController.searchRadius.rawValue)&limit=\(SettingsController.sharedController.fetchLimit.rawValue)" + dateParameterString
    }
    
}
