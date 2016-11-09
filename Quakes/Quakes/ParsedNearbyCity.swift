
import Foundation
import MapKit

class ParsedNearbyCity: NSObject, NSCoding {
    
    // MARK: - Properties
    let distance, latitude, longitude: Double
    
    let cityName, directionString: String
    
    fileprivate let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        formatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
        return formatter
    }()
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: Date.distantFuture)
    }
    
    init(dict: [String: AnyObject]) {
        distance = dict["distance"] as? Double ?? 0.0
        latitude = dict["latitude"] as? Double ?? 0.0
        longitude = dict["longitude"] as? Double ?? 0.0
        
        cityName = dict["name"] as? String ?? ""
        directionString = dict["direction"] as? String ?? ""
    }
    
    // MARK: NSCoding
    required init?(coder decoder: NSCoder) {
        distance = decoder.decodeDouble(forKey: "distance")
        latitude = decoder.decodeDouble(forKey: "latitude")
        longitude = decoder.decodeDouble(forKey: "longitude")
        
        cityName = decoder.decodeObject(forKey: "cityName") as? String ?? ""
        directionString = decoder.decodeObject(forKey: "directionString") as? String ?? ""
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(distance, forKey: "distance")
        coder.encode(latitude, forKey: "latitude")
        coder.encode(longitude, forKey: "longitude")
        coder.encode(cityName, forKey: "cityName")
        coder.encode(directionString, forKey: "directionString")
    }
    
}

extension ParsedNearbyCity: MKAnnotation {
    
    var title: String? {
        return [directionString, cityName].joined(separator: " ")
    }
    
    var subtitle: String? {
        return [distanceFormatter.string(fromDistance: distance * 1000), "from the center of the quake."].joined(separator: " ")
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}
