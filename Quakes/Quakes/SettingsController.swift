
import Foundation
import CoreLocation

class SettingsController
{
    
    static let sharedContoller = SettingsController()
    
    private static let kCachedPlacemarkKey = "cachedPlace"
    private static let kLastSearchedKey = "lastsearched"
    private static let kSearchRadiusKey = "searchRadius"
    private static let kLastLocationOptionKey = "lastLocationOption"
    private static let kUserFirstLaunchedKey = "firstLaunchKey"
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy private var baseDefaults:[String: AnyObject] = {
        return [
            kSearchRadiusKey : 150.0,
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
    
    var searchRadius: Double {
        get {
            return defaults.doubleForKey(SettingsController.kSearchRadiusKey)
        }
        set {
            defaults.setDouble(newValue, forKey: SettingsController.kLastSearchedKey)
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
    
}