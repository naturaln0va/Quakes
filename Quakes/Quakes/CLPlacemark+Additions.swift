
import CoreLocation

extension CLPlacemark {
    
    func cityStateString() -> String
    {
        var wholeString = ""
        
        if let city = self.locality {
            wholeString += city + ", "
        }
        
        if let state = self.administrativeArea {
            wholeString += state
        }
        
        if wholeString.characters.count > 0 {
            return wholeString
        }
        else {
            return "Invalid Address"
        }
    }
    
}