
import Foundation


extension NSDate
{
    
    func hoursSince(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: self, options: []).hour
    }
    
    func daysSince(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
    
    func isMoreThanAWeekOld() -> Bool {
        return NSCalendar.currentCalendar().components(.Day, fromDate: self, toDate: NSDate(), options: []).day > 7
    }
    
    func relativeString() -> String {
        let intervalDifference = NSDate().timeIntervalSinceDate(self)
        
        if intervalDifference <= NSTimeInterval(60 * 2) {
            return "now"
        }
        else if intervalDifference <= NSTimeInterval(60 * 60) {
            return "\(Int(intervalDifference / 60))m"
        }
        
        let daysAgo = NSDate().daysSince(self)
        let hoursAgo = Int(intervalDifference / NSTimeInterval(60 * 60))
        
        if daysAgo <= 1 {
            return "\(hoursAgo)h"
        }
        else if daysAgo <= 6 {
            return "\(daysAgo)d"
        }
        
        let weeksAgo = daysAgo / 7
        if weeksAgo < 52 {
            return "\(weeksAgo)w"
        }
        
        return NSDateFormatter.localizedStringFromDate(
            self, dateStyle: .ShortStyle, timeStyle: .NoStyle
        )
    }
    
}