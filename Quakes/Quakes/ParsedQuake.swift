
import Foundation

enum SourceProvider: Int {
    case Unknown
    case USGS
    case EMSC
}

struct ParsedQuake {
    
    // MARK: Properties.
    let date: NSDate
    
    let identifier, name, link, detailURL: String
    
    let depth, latitude, longitude, magnitude, distance, felt: Double
    
    let provider: Int

    init?(dict: [String: AnyObject]) {
        let id = dict["unid"] as? String ?? dict["id"] as? String
        
        guard let earthquakeID = id where !earthquakeID.isEmpty else { return nil }
        identifier = earthquakeID
        
        let properties = dict["properties"] as? [String: AnyObject] ?? [:]
        
        if let urlString = properties["url"] as? String {
            link = urlString
            provider = SourceProvider.USGS.rawValue
        }
        else if let quakeEMSCID = properties["source_id"] as? String {
            link = "http://www.emsc-csem.org/Earthquake/earthquake.php?id=\(quakeEMSCID)"
            provider = SourceProvider.EMSC.rawValue
        }
        else {
            link = ""
            provider = SourceProvider.Unknown.rawValue
        }
        
        magnitude = properties["mag"] as? Double ?? 0.0
        detailURL = properties["detail"] as? String ?? ""
        
        felt = properties["felt"] as? Double ?? 0.0
        
        if let offset = properties["time"] as? Double {
            date = NSDate(timeIntervalSince1970: offset / 1000)
        }
        else if let dateString = properties["time"] as? String {
            date = NSDateFormatter().dateFromString(dateString) ?? NSDate.distantFuture()
        }
        else {
            date = NSDate.distantFuture()
        }
        
        let origionalNameString = properties["place"] as? String ?? ""
        if origionalNameString.characters.count > 0 && origionalNameString.containsString("km ") {
            let comps = origionalNameString.componentsSeparatedByString("km ")
            name = comps.last ?? ""
            distance = (Double(comps.first ?? "0") ?? 0) * 1000
        }
        else {
            name = ""
            distance = 0
            // need to geocode
        }
        
        let geometry = dict["geometry"] as? [String: AnyObject] ?? [:]
        if let coordinates = geometry["coordinates"] as? [Double] where coordinates.count == 3 {
            longitude = coordinates[0]
            latitude = coordinates[1]
            
            // `depth` is in km, but we want to store it in meters.
            depth = coordinates[2] * 1000
        }
        else {
            return nil
        }
    }
    
}
