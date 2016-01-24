
import Foundation

class ParsedNearbyCity: NSObject, NSCoding
{
    
    // MARK: - Properties
    let distance, latitude, longitude: Double
    
    let cityName, directionString: String
    
    init(dict: [String: AnyObject]) {
        distance = dict["distance"] as? Double ?? 0.0
        latitude = dict["latitude"] as? Double ?? 0.0
        longitude = dict["longitude"] as? Double ?? 0.0
        
        cityName = dict["name"] as? String ?? ""
        directionString = dict["direction"] as? String ?? ""
    }
    
    // MARK: NSCoding
    required init?(coder decoder: NSCoder)
    {
        distance = decoder.decodeDoubleForKey("distance")
        latitude = decoder.decodeDoubleForKey("latitude")
        longitude = decoder.decodeDoubleForKey("longitude")
        
        cityName = decoder.decodeObjectForKey("cityName") as? String ?? ""
        directionString = decoder.decodeObjectForKey("directionString") as? String ?? ""
    }
    
    func encodeWithCoder(coder: NSCoder)
    {
        coder.encodeDouble(distance, forKey: "distance")
        coder.encodeDouble(latitude, forKey: "latitude")
        coder.encodeDouble(longitude, forKey: "longitude")
        coder.encodeObject(cityName, forKey: "cityName")
        coder.encodeObject(directionString, forKey: "directionString")
    }
    
}