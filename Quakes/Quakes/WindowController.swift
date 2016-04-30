

import UIKit


@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate
{
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if SettingsController.sharedController.fisrtLaunchDate == nil {
            SettingsController.sharedController.fisrtLaunchDate = NSDate()
        }
        
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window.rootViewController = StyledNavigationController(rootViewController: QuakesViewController())
        window.makeKeyAndVisible()
        
        self.window = window
        
        Flurry.startSession(TelemetryController.sharedController.apiKey)
        
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
        guard NSDate().daysSince(SettingsController.sharedController.lastPushDate) > 6 else { completionHandler(.NoData); return }
        
        NetworkUtility.networkOperationStarted()
        NetworkClient.sharedClient.getNotificationCountFromStartDate(SettingsController.sharedController.lastPushDate) { count, error in
            NetworkUtility.networkOperationFinished()
            
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

