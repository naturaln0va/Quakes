
import UIKit
import CoreLocation

@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate {
    
    private enum ShortcutItem: String {
        case search
        case nearby
        case felt
    }
    
    var window: UIWindow?
    
    let rootListViewController = ListViewController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        window?.rootViewController = StyledNavigationController(rootViewController: rootListViewController)
        window?.makeKeyAndVisible()
        
        if !UIDevice.current.name.hasSuffix("Simulator") {
            registerForPushNotifications(application)
        }
        
        DispatchQueue.main.async { 
            self.performSecondaryInitializationsWithOptions(launchOptions)
        }
        
        if let item = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            return !handleShortCutItem(item: item)
        }
        
        return true
    }
    
    func performSecondaryInitializationsWithOptions(_ launchOptions: [AnyHashable: Any]?) {
        Flurry.setDebugLogEnabled(false)
        Flurry.setShowErrorInLogEnabled(false)
        Flurry.startSession(TelemetryController.sharedController.apiKey, withOptions: launchOptions)
        
        if !SettingsController.sharedController.hasSupported && SettingsController.sharedController.fisrtLaunchDate == nil {
            NetworkClient.sharedClient.verifyInAppRecipt { sucess in
                if sucess {
                    SettingsController.sharedController.hasSupported = true
                }
            }
        }
        
        if SettingsController.sharedController.fisrtLaunchDate == nil { // first launch
            SettingsController.sharedController.fisrtLaunchDate = Date()
        }
        
        updateShortcutItems()
    }
    
    // MARK: - Notifications
    
    func registerForPushNotifications(_ application: UIApplication) {
        let notificationSettings = UIUserNotificationSettings(
            types: [.sound, .alert],
            categories: nil
        )
        
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != UIUserNotificationType() {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        
        for i in 0..<deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        print("Device Token: \(tokenString), length of token: \(tokenString.characters.count)")
        
        SettingsController.sharedController.pushToken = tokenString
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    // MARK: - Quick Actions
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortCutItem(item: shortcutItem))
    }
    
    func handleShortCutItem(item: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        guard let type = item.type.components(separatedBy: ".").last else {
            return false
        }
        
        switch type {
            
        case ShortcutItem.search.rawValue:
            delay(0.5) {
                self.rootListViewController.presentFinder()
            }
            handled = true
            break
            
        case ShortcutItem.nearby.rawValue:
            delay(0.5) {
                SettingsController.sharedController.lastLocationOption = LocationOption.Nearby.rawValue
                self.rootListViewController.tableView.reloadData()
            }
            handled = true
            break
            
        case ShortcutItem.felt.rawValue:
            handled = true
            break
            
        default: break
        }
        
        return handled
    }
    
    func updateShortcutItems() {
        guard let identifier = Bundle.main.bundleIdentifier else { return }

        var shortcutItems = [UIApplicationShortcutItem]()
        
        let searchAction = UIApplicationShortcutItem(
            type: "\(identifier).\(ShortcutItem.search.rawValue)",
            localizedTitle: "Search",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(type: .search),
            userInfo: nil
        )
        shortcutItems.append(searchAction)
        
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            let recentAction = UIApplicationShortcutItem(
                type: "\(identifier).\(ShortcutItem.nearby.rawValue)",
                localizedTitle: "Nearby",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .location),
                userInfo: nil
            )
            shortcutItems.append(recentAction)
        }
        
        let feltAction = UIApplicationShortcutItem(
            type: "\(identifier).\(ShortcutItem.felt.rawValue)",
            localizedTitle: "I Felt That",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(type: .confirmation),
            userInfo: nil
        )
        shortcutItems.append(feltAction)
        
        UIApplication.shared.shortcutItems = shortcutItems
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: closure
        )
    }
    
}

