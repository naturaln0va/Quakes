
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
        let currentDate = Date()
        let currentCalendar = Calendar.current
        
        var dateParameterString = ""
        if let endDate = (currentCalendar as NSCalendar).date(byAdding: .month, value: -1 * Int(page), to: currentDate, options: [.matchLast]), let startDate = (currentCalendar as NSCalendar).date(byAdding: .month, value: -1, to: endDate, options: [.matchLast]) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateParameterString = "&endtime=\(dateFormatter.string(from: endDate))&starttime=\(dateFormatter.string(from: startDate))"
        }
        
        return "\(baseURLString)query?limit=\(SettingsController.sharedController.fetchLimit.rawValue)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&maxradius=\(radius)&format=json" + dateParameterString
    }
    
}
