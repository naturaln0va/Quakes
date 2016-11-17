
import Foundation

extension Date {
    
    func hoursSince(_ date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    
    func daysSince(_ date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    func monthsSince(_ date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    
    func isToday() -> Bool {
        return (Calendar.current as NSCalendar).components([.year, .month, .day], from: Date(), to: self, options: []).day == 0
    }
    
    func isMoreThanAWeekOld() -> Bool {
        return (Calendar.current as NSCalendar).components(.day, from: self, to: Date(), options: []).day! > 7
    }
    
    func isMoreThanAMonthOld() -> Bool {
        return (Calendar.current as NSCalendar).components(.month, from: self, to: Date(), options: []).month! > 1
    }
    
    func relativeString() -> String {
        let now = Date()
        let intervalDifference = now.timeIntervalSince(self)
        
        if intervalDifference <= TimeInterval(60 * 60) {
            return "\(Int(intervalDifference / 60))m"
        }
        
        let daysAgo = now.daysSince(self)
        
        if daysAgo <= 1 {
            let hoursAgo = Int(intervalDifference / TimeInterval(60 * 60))
            return "\(hoursAgo)h"
        }
        else if daysAgo <= 6 {
            return "\(daysAgo)d"
        }
        
        let weeksAgo = daysAgo / 7
        if weeksAgo < 52 {
            return "\(weeksAgo)w"
        }
        
        return DateFormatter.localizedString(
            from: self, dateStyle: .short, timeStyle: .none
        )
    }
    
}
