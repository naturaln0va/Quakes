
import Foundation
import CoreData
import CoreLocation
import MapKit


class Quake: NSManagedObject {
    
    // MARK: Formatters
    static let timestampFormatter: NSDateFormatter = {
        let timestampFormatter = NSDateFormatter()
        
        timestampFormatter.dateStyle = .MediumStyle
        timestampFormatter.timeStyle = .MediumStyle
        
        return timestampFormatter
    }()
    
    static let magnitudeFormatter: NSNumberFormatter = {
        let magnitudeFormatter = NSNumberFormatter()
        
        magnitudeFormatter.numberStyle = .DecimalStyle
        magnitudeFormatter.maximumFractionDigits = 1
        magnitudeFormatter.minimumFractionDigits = 1
        
        return magnitudeFormatter
    }()
    
    static let depthFormatter: NSLengthFormatter = {
        
        let depthFormatter = NSLengthFormatter()
        depthFormatter.forPersonHeightUse = false
        
        return depthFormatter
    }()
    
    static let distanceFormatter: NSLengthFormatter = {
        let distanceFormatter = NSLengthFormatter()
        
        distanceFormatter.forPersonHeightUse = false
        distanceFormatter.numberFormatter.maximumFractionDigits = 2
        
        return distanceFormatter
    }()
    
    // MARK: - Properties
    @NSManaged var depth: Double
    @NSManaged var weblink: String
    @NSManaged var timestamp: NSDate
    @NSManaged var name: String
    @NSManaged var magnitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var identifier: String
    @NSManaged var detailURL: String
    @NSManaged var nearbyCitiesData: NSData?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: -depth, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: timestamp)
    }
    
    var nearbyCities: [ParsedNearbyCity]? {
        if let data = nearbyCitiesData {
            if let cities = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [ParsedNearbyCity] {
                return cities
            }
        }
        return nil
    }
    
}

extension Quake: Fetchable {
    
    typealias FetchableType = Quake
    
    static func entityName() -> String
    {
        return "Quake"
    }
    
}

extension Quake: MKAnnotation {
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        let formatter = NSNumberFormatter()
        
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        
        let timestampFormatter = NSDateFormatter()
        
        timestampFormatter.dateStyle = .MediumStyle
        timestampFormatter.timeStyle = .MediumStyle

        return formatter.stringFromNumber(magnitude)! + ", at " + timestampFormatter.stringFromDate(timestamp)
    }
}
