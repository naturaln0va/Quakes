
import UIKit

class RecentQuakeCountOperation: NetworkOperation {

    let baseURLString = "http://earthquake.usgs.gov/fdsnws/event/1/"
    
    override var urlString: String {
        if let lastSearchedLocation = SettingsController.sharedController.lastSearchedPlace?.location {
            return "\(baseURLString)count?format=geojson&latitude=\(lastSearchedLocation.coordinate.latitude)&longitude=\(lastSearchedLocation.coordinate.longitude)&maxradiuskm=\(SettingsController.sharedController.searchRadius.rawValue)&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
        }
        else if SettingsController.sharedController.lastLocationOption == LocationOption.Major.rawValue {
            return "\(baseURLString)count?format=geojson&minmagnitude=3.8&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
        }
        else if SettingsController.sharedController.lastLocationOption == LocationOption.World.rawValue {
            return "\(baseURLString)count?format=geojson&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
        }
        else {
            guard let cachedAddressLocation = SettingsController.sharedController.cachedAddress?.location else {
                print("WARNING: tried to fetch quake count for an invalid location.")
                cancel()
                return ""
            }
            
            return "\(baseURLString)count?format=geojson&latitude=\(cachedAddressLocation.coordinate.latitude)&longitude=\(cachedAddressLocation.coordinate.longitude)&maxradiuskm=\(SettingsController.sharedController.searchRadius.rawValue)&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
        }
        
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
//        
//        params?.append((ParamTypes.StartTime.rawValue, dateFormatter.stringFromDate(startDate)))
    }
    
    override func handleData() {
        let stringFromResponseData = String(data: incomingData, encoding: NSUTF8StringEncoding)
        
        print("string from data :\(stringFromResponseData)")
    }
    
}
