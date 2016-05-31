
import UIKit

@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window?.rootViewController = StyledNavigationController(rootViewController: ListViewController())
        window?.makeKeyAndVisible()
        
        if !UIDevice.currentDevice().name.hasSuffix("Simulator") {
            registerForPushNotifications(application)
        }
        
        dispatch_async(dispatch_get_main_queue()) { 
            self.performSecondaryInitializationsWithOptions(launchOptions)
        }
        return true
    }
    
    func performSecondaryInitializationsWithOptions(launchOptions: [NSObject: AnyObject]?) {
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
            SettingsController.sharedController.fisrtLaunchDate = NSDate()
        }
    }
    
    // MARK: - Notifications
    
    func registerForPushNotifications(application: UIApplication) {
        let notificationSettings = UIUserNotificationSettings(
            forTypes: [.Sound, .Alert],
            categories: nil
        )
        
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != .None {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
        var tokenString = ""
        
        for i in 0..<deviceToken.length {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        print("Device Token: \(tokenString), length of token: \(tokenString.characters.count)")
        
        SettingsController.sharedController.pushToken = tokenString
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Failed to register: \(error)")
    }
}

