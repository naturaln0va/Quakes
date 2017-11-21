
import Foundation
import CoreLocation

class SettingsController {
    
    static let kSettingsControllerDidChangeUnitStyleNotification = "settingsControllerDidChangeUnitStyle"
    static let kSettingsControllerDidChangePurchaseAdRemovalNotification = "settingsControllerDidChangePurchaseAdRemoval"
    static let kSettingsControllerDidUpdateLastFetchDateNotification = "settingsControllerDidUpdateLastFetchDate"
    static let kSettingsControllerDidUpdateLocationForPushNotification = "settingsControllerDidUpdateLocationForPush"
    
    enum APIFetchSize: Int {
        case small = 100
        case medium = 225
        case large = 400
        case extraLarge = 1000
        
        func displayString() -> String {
            switch self {
            case .small:
                return "Small"
            case .medium:
                return "Medium"
            case .large:
                return "Large"
            case .extraLarge:
                return "ExtraLarge"
            }
        }
        
        static func closestValueForInteger(_ value: Int) -> APIFetchSize {
            switch value {
            case APIFetchSize.small.rawValue:
                return .small
            case APIFetchSize.medium.rawValue:
                return .medium
            case APIFetchSize.large.rawValue:
                return .large
            case APIFetchSize.extraLarge.rawValue:
                return .extraLarge
            default:
                fatalError("PROGRAMMING ERROR: You didn't specify a correct value")
            }
        }
    }
    
    enum SearchRadiusSize: Int {
        case small = 50
        case medium = 150
        case large = 275
        case extraLarge = 750
        
        func displayString() -> String {
            switch self {
            case .small:
                return "Small"
            case .medium:
                return "Medium"
            case .large:
                return "Large"
            case .extraLarge:
                return "ExtraLarge"
            }
        }
        
        static func closestValueForInteger(_ value: Int) -> SearchRadiusSize {
            switch value {
            case SearchRadiusSize.small.rawValue:
                return .small
            case SearchRadiusSize.medium.rawValue:
                return .medium
            case SearchRadiusSize.large.rawValue:
                return .large
            case SearchRadiusSize.extraLarge.rawValue:
                return .extraLarge
            default:
                fatalError("PROGRAMMING ERROR: You didn't specify a correct value \(value)")
            }
        }
    }
    
    static let sharedController = SettingsController()
    
    fileprivate static let kCachedPlacemarkKey = "cachedPlace"
    fileprivate static let kLastSearchedKey = "lastsearched"
    fileprivate static let kSearchRadiusKey = "searchRadius"
    fileprivate static let kFetchSizeLimitKey = "fetchLimit"
    fileprivate static let kUnitStyleKey = "unitStyle"
    fileprivate static let kLastLocationOptionKey = "lastLocationOption"
    fileprivate static let kUserFirstLaunchedKey = "firstLaunchKey"
    fileprivate static let kLastPushKey = "lastPush"
    fileprivate static let kLastFetchKey = "lastFetch"
    fileprivate static let kPaidToRemoveKey = "alreadyPaid"
    fileprivate static let kHasAttemptedNotificationKey = "attemptedNotification"
    fileprivate static let kPushTokenKey = "pushToken"
    
    fileprivate let defaults = UserDefaults.standard
    
    lazy fileprivate var baseDefaults:[String: Any] = {
        return [
            SettingsController.kSearchRadiusKey: SearchRadiusSize.medium.rawValue,
            SettingsController.kFetchSizeLimitKey: APIFetchSize.medium.rawValue,
            SettingsController.kLastPushKey: Date.distantPast,
            SettingsController.kHasAttemptedNotificationKey: false,
            SettingsController.kPaidToRemoveKey: false,
            SettingsController.kUnitStyleKey: true
        ]
    }()
    
    // MARK: - Init
    init() {
        loadSettings()
    }
    
    // MARK: - Private
    fileprivate func loadSettings() {
        defaults.register(defaults: baseDefaults)
    }
    
    // MARK: - Helper
    func hasSearchedBefore() -> Bool {
        return lastLocationOption == nil && lastSearchedPlace == nil && cachedAddress == nil
    }
    
    func isLocationOptionWorldOrMajor() -> Bool {
        return lastLocationOption == LocationOption.world.rawValue || lastLocationOption == LocationOption.major.rawValue
    }
    
    func locationEligableForNotifications() -> CLLocation? {
        if let lastSearch = lastSearchedPlace, lastSearch.location != nil {
            return lastSearch.location
        }
        else if let lastAddress = cachedAddress, lastAddress.location != nil {
            return lastAddress.location
        }
        else {
            return nil
        }
    }
        
    // MARK: - Public
    var cachedAddress: CLPlacemark? {
        get {
            if let data = defaults.object(forKey: SettingsController.kCachedPlacemarkKey) as? Data,
                let place = NSKeyedUnarchiver.unarchiveObject(with: data) as? CLPlacemark {
                    return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: newPlace)
                defaults.set(data, forKey: SettingsController.kCachedPlacemarkKey)
                defaults.synchronize()
                NotificationCenter.default.post(name: Notification.Name(rawValue: SettingsController.kSettingsControllerDidUpdateLocationForPushNotification), object: nil)
            }
            else {
                defaults.set(nil, forKey: SettingsController.kCachedPlacemarkKey)
                defaults.synchronize()
            }
        }
    }
    
    var lastSearchedPlace: CLPlacemark? {
        get {
            if let data = defaults.object(forKey: SettingsController.kLastSearchedKey) as? Data,
                let place = NSKeyedUnarchiver.unarchiveObject(with: data) as? CLPlacemark {
                return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: newPlace)
                defaults.set(data, forKey: SettingsController.kLastSearchedKey)
                defaults.synchronize()
                NotificationCenter.default.post(name: Notification.Name(rawValue: SettingsController.kSettingsControllerDidUpdateLocationForPushNotification), object: nil)
            }
            else {
                defaults.set(nil, forKey: SettingsController.kLastSearchedKey)
                defaults.synchronize()
            }
        }
    }
    
    var pushToken: String? {
        get {
            return defaults.string(forKey: SettingsController.kPushTokenKey)
        }
        set {
            defaults.set(newValue, forKey: SettingsController.kPushTokenKey)
            defaults.synchronize()
        }
    }
    
    var hasAttemptedNotificationPermission: Bool {
        get {
            return defaults.bool(forKey: SettingsController.kHasAttemptedNotificationKey)
        }
        set {
            defaults.set(newValue, forKey: SettingsController.kHasAttemptedNotificationKey)
            defaults.synchronize()
        }
    }
    
    var hasSupported: Bool {
        get {
            return defaults.bool(forKey: SettingsController.kPaidToRemoveKey)
        }
        set {
            defaults.set(newValue, forKey: SettingsController.kPaidToRemoveKey)
            defaults.synchronize()
            NotificationCenter.default.post(name: Notification.Name(rawValue: type(of: self).kSettingsControllerDidChangePurchaseAdRemovalNotification), object: nil)
        }
    }
    
    var isUnitStyleImperial: Bool {
        get {
            return defaults.bool(forKey: SettingsController.kUnitStyleKey)
        }
        set {
            defaults.set(newValue, forKey: SettingsController.kUnitStyleKey)
            defaults.synchronize()
            NotificationCenter.default.post(name: Notification.Name(rawValue: type(of: self).kSettingsControllerDidChangeUnitStyleNotification), object: nil)
        }
    }
    
    var lastLocationOption: String? {
        get {
            return defaults.string(forKey: SettingsController.kLastLocationOptionKey)
        }
        set {
            defaults.set(newValue, forKey: SettingsController.kLastLocationOptionKey)
            defaults.synchronize()
        }
    }
    
    var searchRadius: SearchRadiusSize {
        get {
            return ProcessInfo.processInfo.isLowPowerModeEnabled ? .small : SearchRadiusSize.closestValueForInteger(defaults.integer(forKey: SettingsController.kSearchRadiusKey))
        }
        set {
            defaults.set(newValue.rawValue, forKey: SettingsController.kSearchRadiusKey)
            defaults.synchronize()
        }
    }
    
    var fetchLimit: APIFetchSize {
        get {
            return ProcessInfo.processInfo.isLowPowerModeEnabled ? .small : APIFetchSize.closestValueForInteger(defaults.integer(forKey: SettingsController.kFetchSizeLimitKey))
        }
        set {
            defaults.set(newValue.rawValue, forKey: SettingsController.kFetchSizeLimitKey)
            defaults.synchronize()
        }
    }
    
    var fisrtLaunchDate: Date? {
        get {
            let launchTimeInterval = defaults.double(forKey: SettingsController.kUserFirstLaunchedKey)
            if launchTimeInterval == 0 {
                defaults.set(Date().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
                defaults.synchronize()

                return nil
            }
            else {
                return Date(timeIntervalSince1970: launchTimeInterval)
            }
        }
        set {
            defaults.set(Date().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
            defaults.synchronize()
        }
    }
    
    var lastPushDate: Date {
        get {
            let interval = defaults.double(forKey: SettingsController.kLastPushKey)
            return interval == 0 ? Date.distantPast : Date(timeIntervalSince1970: interval)
        }
        set {
            defaults.set(newValue.timeIntervalSince1970, forKey: SettingsController.kLastPushKey)
            defaults.synchronize()
        }
    }
    
    var lastFetchDate: Date {
        get {
            let interval = defaults.double(forKey: SettingsController.kLastFetchKey)
            return interval == 0 ? Date.distantPast : Date(timeIntervalSince1970: interval)
        }
        set {
            NotificationCenter.default.post(name: Notification.Name(rawValue: type(of: self).kSettingsControllerDidUpdateLastFetchDateNotification), object: nil)
            defaults.set(newValue.timeIntervalSince1970, forKey: SettingsController.kLastFetchKey)
            defaults.synchronize()
        }
    }
    
}
