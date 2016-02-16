

import UIKit


@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate
{
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window.rootViewController = StyledNavigationController(rootViewController: QuakesViewController())
        window.makeKeyAndVisible()
        
        self.window = window
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        if !SettingsController.sharedController.hasSupported {
            NetworkClient.sharedClient.verifyInAppRecipt { sucess in
                if sucess {
                    SettingsController.sharedController.hasSupported = true
                }
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        guard NetworkUtility.internetReachable() else { completionHandler(.Failed); return }
        guard SettingsController.sharedController.hasAttemptedNotificationPermission else { completionHandler(.Failed); return }
        guard let notificationSettings = application.currentUserNotificationSettings() where notificationSettings.types != .None else { completionHandler(.Failed); return }
        guard NSDate().hoursSince(SettingsController.sharedController.lastPushDate) > SettingsController.sharedController.notificationLimitForType() else { completionHandler(.NoData); return }
        
        NetworkUtility.networkOperationStarted()
        NetworkClient.sharedClient.getNotificationCountFromStartDate(SettingsController.sharedController.lastPushDate) { count, error in
            NetworkUtility.networkOperationFinished()
            
            if let count = count where error == nil && count > 0 {
                completionHandler(.NewData)
                self.postLocalNotificationWithNumberOfNewQuakes(count)
            }
            else {
                completionHandler(.Failed)
            }
        }
    }
    
    internal func postLocalNotificationWithNumberOfNewQuakes(newQuakes: Int) {
        let hoursDifference = NSDate().hoursSince(SettingsController.sharedController.lastPushDate)
        SettingsController.sharedController.lastPushDate = NSDate()
        
        var partOne = newQuakes == 1 ? "1 quake happened" : "\(newQuakes) quakes happened"
        var partTwo = ""
        if let lastSearchedLocation = SettingsController.sharedController.lastSearchedPlace {
            partTwo = "near \(lastSearchedLocation.cityStateString())"
        }
        else if SettingsController.sharedController.lastLocationOption == LocationOption.World.rawValue {
            if newQuakes > 1 {
                partTwo = "worldwide"
            }
            else {
                return
            }
        }
        else if SettingsController.sharedController.lastLocationOption == LocationOption.Major.rawValue {
            partOne = newQuakes == 1 ? "A major quake happened" : "\(newQuakes) major quakes happened"
            
            if newQuakes > 1 {
                partTwo = "worldwide"
            }
            else {
                return
            }
        }
        else {
            guard let cachedAddressLocation = SettingsController.sharedController.cachedAddress else {
                print("WARNING: tried to fetch quake count for an invalid location.")
                return
            }
            partTwo = "near \(cachedAddressLocation.cityStateString())"
        }
        var partThree = ""
        if hoursDifference < 23 {
                partThree = hoursDifference == 1 ? "within the last hour." : "in the past \(hoursDifference) hours."
        }
        else if hoursDifference < 24 * 7 {
            partThree = "yesterday."
        }
        else {
            partThree = "last week."
        }
        
        let notification = UILocalNotification()
        notification.alertBody = [partOne, partTwo, partThree].joinWithSeparator(" ")
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
}

