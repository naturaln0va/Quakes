
import UIKit

@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        window?.rootViewController = StyledNavigationController(rootViewController: ListViewController())
        window?.makeKeyAndVisible()
        
        if !UIDevice.current.name.hasSuffix("Simulator") {
            registerForPushNotifications(application)
        }
        
        DispatchQueue.main.async { 
            self.performSecondaryInitializationsWithOptions(launchOptions)
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
        
        if SettingsController.sharedController.fisrtLaunchDate == nil {
            SettingsController.sharedController.fisrtLaunchDate = Date()
        }
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
}

