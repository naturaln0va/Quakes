
import CoreLocation

extension CLPlacemark {
    
    func cityStateString() -> String {
        var wholeString = ""
        
        if let city = self.locality {
            wholeString += city + ", "
        }
        
        if let state = self.administrativeArea {
            wholeString += state
        }
        
        if wholeString.count > 0 {
            return wholeString
        }
        else {
            if self.country != nil {
                return self.country!
            }
            else {
                print("Malformed address: \(self)")
                return "Invalid Address"
            }
        }
    }
    
}
