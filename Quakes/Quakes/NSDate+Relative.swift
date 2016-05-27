
import Foundation


extension NSDate
{
    
    func hoursSince(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: self, options: []).hour
    }
    
    func daysSince(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
    
    func isToday() -> Bool {
        return NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: NSDate(), toDate: self, options: []).day == 0
    }
    
    func isMoreThanAWeekOld() -> Bool {
        return NSCalendar.currentCalendar().components(.Day, fromDate: self, toDate: NSDate(), options: []).day > 7
    }
    
    func isMoreThanAMonthOld() -> Bool {
        return NSCalendar.currentCalendar().components(.Month, fromDate: self, toDate: NSDate(), options: []).month > 1
    }
    
    func relativeString() -> String {
        let now = NSDate()
        let intervalDifference = now.timeIntervalSinceDate(self)
        
        if intervalDifference <= NSTimeInterval(60 * 60) {
            return "\(Int(intervalDifference / 60))m"
        }
        
        let daysAgo = now.daysSince(self)
        
        if daysAgo <= 1 {
            let hoursAgo = Int(intervalDifference / NSTimeInterval(60 * 60))
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