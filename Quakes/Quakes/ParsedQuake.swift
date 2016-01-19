
import Foundation

struct ParsedQuake
{
    
    // MARK: Properties.
    let date: NSDate
    
    let identifier, name, link, detailURL: String
    
    let depth, latitude, longitude, magnitude: Double

    init?(dict: [String: AnyObject]) {
        guard let earthquakeID = dict["id"] as? String where !earthquakeID.isEmpty else { return nil }
        identifier = earthquakeID
        
        let properties = dict["properties"] as? [String: AnyObject] ?? [:]
        
        name = properties["place"] as? String ?? ""
        
        link = properties["url"] as? String ?? ""
        
        magnitude = properties["mag"] as? Double ?? 0.0
        
        detailURL = properties["detail"] as? String ?? ""
        
        if let offset = properties["time"] as? Double {
            date = NSDate(timeIntervalSince1970: offset / 1000)
        }
        else {
            date = NSDate.distantFuture()
        }
        
        
        let geometry = dict["geometry"] as? [String: AnyObject] ?? [:]
        
        if let coordinates = geometry["coordinates"] as? [Double] where coordinates.count == 3 {
            longitude = coordinates[0]
            latitude = coordinates[1]
            
            // `depth` is in km, but we want to store it in meters.
            depth = coordinates[2] * 1000
        }
        else {
            depth = 0
            latitude = 0
            longitude = 0
        }
    }
    
}
