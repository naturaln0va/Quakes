
import Foundation
import CoreData
import CoreLocation
import MapKit


class Quake: NSManagedObject {
    
    // MARK: Formatters
    static let timestampFormatter: DateFormatter = {
        let timestampFormatter = DateFormatter()
        
        timestampFormatter.dateStyle = .medium
        timestampFormatter.timeStyle = .short
        
        return timestampFormatter
    }()
    
    static let magnitudeFormatter: NumberFormatter = {
        let magnitudeFormatter = NumberFormatter()
        
        magnitudeFormatter.numberStyle = .decimal
        magnitudeFormatter.maximumFractionDigits = 1
        magnitudeFormatter.minimumFractionDigits = 1
        
        return magnitudeFormatter
    }() 
    
    static let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        formatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
        return formatter
    }()
    
    // MARK: - Properties
    @NSManaged var depth: Double
    @NSManaged var timestamp: Date
    @NSManaged var name: String
    @NSManaged var magnitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var identifier: String
    @NSManaged var detailURL: String
    @NSManaged var felt: Double
    @NSManaged var provider: Int16

    @NSManaged var weblink: String?
    @NSManaged var polyData: Data?
    @NSManaged var nearbyCitiesData: Data?
    @NSManaged var distance: NSNumber?
    @NSManaged var countryCode: String?
    
    var additionalInfoString: String {        
        Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
        return "Depth: \(Quake.distanceFormatter.string(fromDistance: depth))"
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: -depth, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: timestamp)
    }
    
    var severityColor: UIColor {
        if magnitude >= 6.5 {
            return StyleController.purpleColor
        }
        else if magnitude >= 4.0 {
            return StyleController.redQuakeColor
        }
        else if magnitude >= 3.0 {
            return StyleController.orangeQuakeColor
        }
        else {
            return StyleController.greenQuakeColor
        }
    }
    
    var stringForProvider: String {
        return Int(provider) == SourceProvider.usgs.rawValue ? "USGS" : "EMSC"
    }
    
    var nearbyCities: [ParsedNearbyCity]? {
        if let data = nearbyCitiesData {
            if let cities = NSKeyedUnarchiver.unarchiveObject(with: data) as? [ParsedNearbyCity] {
                return cities
            }
        }
        return nil
    }
    
}

extension Quake: Fetchable {
    
    typealias FetchableType = Quake
    
    static func entityName() -> String {
        return "Quake"
    }
    
}

extension Quake: MKAnnotation {
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        let formatter = NumberFormatter()
        
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        
        let timestampFormatter = DateFormatter()
        
        timestampFormatter.dateStyle = .medium
        timestampFormatter.timeStyle = .medium

        return formatter.string(from: NSNumber(value: magnitude))! + ", at " + timestampFormatter.string(from: timestamp)
    }
}
