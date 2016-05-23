

import UIKit


@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate
{
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window.rootViewController = StyledNavigationController(rootViewController: ListViewController())
        window.makeKeyAndVisible()
        
        self.window = window
        
        Flurry.startSession(TelemetryController.sharedController.apiKey)
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        registerForPushNotifications(application)
        
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
        
        return true
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
        
        if let address = SettingsController.sharedController.cachedAddress where address.location != nil {
            NetworkClient.sharedClient.registerForNotificationsWithToken(tokenString, location: address.location!)
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Failed to register: \(error)")
    }
    
    // MARK: - Background Fetch
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        guard NetworkUtility.internetReachable() else { completionHandler(.Failed); return }
        
        if let lastPlace = SettingsController.sharedController.lastSearchedPlace {
            NetworkClient.sharedClient.getQuakesByLocation(0, coordinate: lastPlace.location!.coordinate) { quakes, error in
                if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                if error == nil {
                    completionHandler(.NewData)
                }
                else {
                    completionHandler(.Failed)
                }
            }
            return
        }
        
        if let option = SettingsController.sharedController.lastLocationOption {
            switch option {
            case LocationOption.Nearby.rawValue:
                if let current = SettingsController.sharedController.cachedAddress?.location {
                    NetworkClient.sharedClient.getQuakesByLocation(0, coordinate: current.coordinate) { quakes, error in
                        if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                        if error == nil {
                            completionHandler(.NewData)
                        }
                        else {
                            completionHandler(.Failed)
                        }
                    }
                }
                else {
                    completionHandler(.Failed)
                }
                break
            case LocationOption.World.rawValue:
                NetworkClient.sharedClient.getWorldQuakes(0) { quakes, error in
                    if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                    if error == nil {
                        completionHandler(.NewData)
                    }
                    else {
                        completionHandler(.Failed)
                    }
                }
                break
            case LocationOption.Major.rawValue:
                NetworkClient.sharedClient.getMajorQuakes(0) { quakes, error in
                    if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                    if error == nil {
                        completionHandler(.NewData)
                    }
                    else {
                        completionHandler(.Failed)
                    }
                }
                break
                
            default:
                completionHandler(.Failed)
                break
            }
        }
        
        guard SettingsController.sharedController.hasAttemptedNotificationPermission else { completionHandler(.Failed); return }
        guard let notificationSettings = application.currentUserNotificationSettings() where notificationSettings.types != .None else { completionHandler(.Failed); return }
        guard NSDate().daysSince(SettingsController.sharedController.lastPushDate) > 6 else { completionHandler(.NoData); return }
        
        NetworkClient.sharedClient.getNotificationCountFromStartDate(SettingsController.sharedController.lastPushDate) { count, error in
            if let count = count where error == nil && count > 1 {
                completionHandler(.NewData)
                self.postLocalNotificationWithNumberOfNewQuakes(count)
            }
            else {
                completionHandler(.Failed)
            }
        }
    }
    
    internal func postLocalNotificationWithNumberOfNewQuakes(newQuakes: Int) {
        SettingsController.sharedController.lastPushDate = NSDate()
        
        let notification = UILocalNotification()
        notification.alertBody = "\(newQuakes) quakes happened last week"
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
}

