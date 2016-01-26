
import Foundation
import CoreLocation

let kSettingsControllerDidChangeUnitStyleNotification: String = "settingsControllerDidChangeUnitStyle"


class SettingsController
{
    
    enum APIFetchSize: Int {
        case Small = 100
        case Medium = 225
        case Large = 400
        case ExtraLarge = 1000
        
        func displayString() -> String {
            switch self {
            case .Small:
                return "Small"
            case .Medium:
                return "Medium"
            case .Large:
                return "Large"
            case .ExtraLarge:
                return "ExtraLarge"
            }
        }
        
        static func closestValueForInteger(value: Int) -> APIFetchSize {
            switch value {
            case APIFetchSize.Small.rawValue:
                return .Small
            case APIFetchSize.Medium.rawValue:
                return .Medium
            case APIFetchSize.Large.rawValue:
                return .Large
            case APIFetchSize.ExtraLarge.rawValue:
                return .ExtraLarge
            default:
                fatalError("PROGRAMMING ERROR: You didn't specify a correct value")
            }
        }
    }
    
    enum SearchRadiusSize: Int {
        case Small = 50
        case Medium = 150
        case Large = 275
        case ExtraLarge = 750
        
        func displayString() -> String {
            switch self {
            case .Small:
                return "Small"
            case .Medium:
                return "Medium"
            case .Large:
                return "Large"
            case .ExtraLarge:
                return "ExtraLarge"
            }
        }
        
        static func closestValueForInteger(value: Int) -> SearchRadiusSize {
            switch value {
            case SearchRadiusSize.Small.rawValue:
                return .Small
            case SearchRadiusSize.Medium.rawValue:
                return .Medium
            case SearchRadiusSize.Large.rawValue:
                return .Large
            case SearchRadiusSize.ExtraLarge.rawValue:
                return .ExtraLarge
            default:
                fatalError("PROGRAMMING ERROR: You didn't specify a correct value \(value)")
            }
        }
    }
    
    static let sharedController = SettingsController()
    
    private static let kCachedPlacemarkKey = "cachedPlace"
    private static let kLastSearchedKey = "lastsearched"
    private static let kSearchRadiusKey = "searchRadius"
    private static let kFetchSizeLimitKey = "fetchLimit"
    private static let kUnitStyleKey = "unitStyle"
    private static let kLastLocationOptionKey = "lastLocationOption"
    private static let kUserFirstLaunchedKey = "firstLaunchKey"
    private static let kLastFetchedKey = "lastFetch"
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy private var baseDefaults:[String: AnyObject] = {
        return [
            kSearchRadiusKey: SearchRadiusSize.Medium.rawValue,
            kFetchSizeLimitKey: APIFetchSize.Medium.rawValue,
            kUnitStyleKey: true
        ]
    }()
    
    // MARK: - Init
    init()
    {
        loadSettings()
    }
    
    // MARK: - Private
    private func loadSettings()
    {
        defaults.registerDefaults(baseDefaults)
    }
    
    // MARK: - Public
    var cachedAddress: CLPlacemark? {
        get {
            if let data = defaults.objectForKey(SettingsController.kCachedPlacemarkKey) as? NSData,
                let place = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CLPlacemark {
                    return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                let data = NSKeyedArchiver.archivedDataWithRootObject(newPlace)
                defaults.setObject(data, forKey: SettingsController.kCachedPlacemarkKey)
                defaults.synchronize()
            }
            else {
                defaults.setObject(nil, forKey: SettingsController.kCachedPlacemarkKey)
                defaults.synchronize()
            }
        }
    }
    
    var isUnitStyleImperial: Bool {
        get {
            return defaults.boolForKey(SettingsController.kUnitStyleKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kUnitStyleKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(kSettingsControllerDidChangeUnitStyleNotification, object: nil)
        }
    }
    
    var lastSearchedPlace: CLPlacemark? {
        get {
            if let data = defaults.objectForKey(SettingsController.kLastSearchedKey) as? NSData,
                let place = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CLPlacemark {
                    return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                let data = NSKeyedArchiver.archivedDataWithRootObject(newPlace)
                defaults.setObject(data, forKey: SettingsController.kLastSearchedKey)
                defaults.synchronize()
            }
            else {
                defaults.setObject(nil, forKey: SettingsController.kLastSearchedKey)
                defaults.synchronize()
            }
        }
    }
    
    var lastLocationOption: String? {
        get {
            return defaults.stringForKey(SettingsController.kLastLocationOptionKey)
        }
        set {
            defaults.setObject(newValue, forKey: SettingsController.kLastLocationOptionKey)
            defaults.synchronize()
        }
    }
    
    var searchRadius: SearchRadiusSize {
        get {
            return SearchRadiusSize.closestValueForInteger(defaults.integerForKey(SettingsController.kSearchRadiusKey))
        }
        set {
            defaults.setInteger(newValue.rawValue, forKey: SettingsController.kSearchRadiusKey)
            defaults.synchronize()
        }
    }
    
    var fetchLimit: APIFetchSize {
        get {
            return APIFetchSize.closestValueForInteger(defaults.integerForKey(SettingsController.kFetchSizeLimitKey))
        }
        set {
            defaults.setInteger(newValue.rawValue, forKey: SettingsController.kFetchSizeLimitKey)
            defaults.synchronize()
        }
    }
    
    var fisrtLaunchDate: NSDate? {
        get {
            let launchTimeInterval = defaults.doubleForKey(SettingsController.kUserFirstLaunchedKey)
            if launchTimeInterval == 0 {
                defaults.setDouble(NSDate().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
                defaults.synchronize()

                return nil
            }
            else {
                return NSDate(timeIntervalSince1970: launchTimeInterval)
            }
        }
        set {
            defaults.setDouble(NSDate().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
            defaults.synchronize()
        }
    }
    
    var lastFetchDate: NSDate? {
        get {
            let interval = defaults.doubleForKey(SettingsController.kUserFirstLaunchedKey)
            return interval == 0 ? nil : NSDate(timeIntervalSince1970: interval)
        }
        set {
            if let newDate = newValue {
                defaults.setDouble(newDate.timeIntervalSince1970, forKey: SettingsController.kLastFetchedKey)
                defaults.synchronize()
            }
        }
    }
    
}