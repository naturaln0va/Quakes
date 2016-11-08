
import UIKit

class EMSCWorldOperation: EMSCFetchQuakesOperation {
    
    let page: UInt
    
    init(page: UInt) {
        self.page = page
    }
    
    override var urlString: String {
        let currentDate = Date()
        let currentCalendar = Calendar.current
        
        var dateParameterString = ""
        if let endDate = (currentCalendar as NSCalendar).date(byAdding: .month, value: -1 * Int(page), to: currentDate, options: [.matchLast]), let startDate = (currentCalendar as NSCalendar).date(byAdding: .month, value: -1, to: endDate, options: [.matchLast]) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateParameterString = "&endtime=\(dateFormatter.string(from: endDate))&starttime=\(dateFormatter.string(from: startDate))"
        }

        return "\(baseURLString)query?limit=\(SettingsController.sharedController.fetchLimit.rawValue)&format=json" + dateParameterString
    }
    
}
