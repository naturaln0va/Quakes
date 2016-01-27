
import Foundation

func relativeStringForDate(date: NSDate) -> String
{
    let units:NSCalendarUnit = [.Minute, .Hour, .Day, .WeekOfYear, .Month, .Year]
    
    // if "date" is before "now" (i.e. in the past) then the components will be positive
    let components: NSDateComponents = NSCalendar.currentCalendar().components(units, fromDate: date, toDate: NSDate(), options: [])
    
    if components.weekOfYear > 0 {
        return "\(components.weekOfYear)w"
    }
    else if components.day > 0 {
        return "\(components.day)d"
    }
    else {
        if components.hour > 0 {
            return "\(components.hour)h"
        }
        else if components.minute > 1 {
            return "\(components.minute)m"
        }
        else {
            return "now"
        }
    }
}

extension String
{
    
    init?(contentsOfBundleFileNamed fileName: String) {
        let comps = fileName.componentsSeparatedByString(".")
        if let path = NSBundle.mainBundle().pathForResource(comps.first, ofType: comps.last) where comps.count == 2 {
            do {
                self = try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            }
            
            catch {
                print("Error searching for file: \(fileName)")
                return nil
            }
        }
        else {
            return nil
        }
    }
    
}
