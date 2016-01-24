
import Foundation
import MapKit

class ParsedNearbyCity: NSObject, NSCoding
{
    
    // MARK: - Properties
    let distance, latitude, longitude: Double
    
    let cityName, directionString: String
    
    private let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        formatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
        return formatter
    }()
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: NSDate.distantFuture())
    }
    
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

extension ParsedNearbyCity: MKAnnotation
{
    
    var title: String? {
        return [directionString, cityName].joinWithSeparator(" ")
    }
    
    var subtitle: String? {
        return [distanceFormatter.stringFromDistance(distance), directionString].joinWithSeparator(" ")
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}
