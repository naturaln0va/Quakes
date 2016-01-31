

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
        
//        let cal = NSCalendar.currentCalendar()
//        let comps = cal.components([.Year, .Day, .Hour], fromDate: NSDate())
//        comps.hour -= 1
//        if let threeHoursAgo = cal.dateFromComponents(comps) {
//            NetworkUtility.networkOperationStarted()
//            NetworkClient.sharedClient.getNotificationCountFromStartDate(threeHoursAgo) { count, error in
//                NetworkUtility.networkOperationFinished()
//                
//                if let count = count where error == nil {
//                    print("Number of quakes: \(count), from \(NSDate().hoursFrom(threeHoursAgo)) hours ago.")
//                }
//            }
//        }
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        if !SettingsController.sharedController.hasPaidToRemoveAds {
            NetworkClient.sharedClient.verifyInAppRecipt { sucess in
                if sucess {
                    SettingsController.sharedController.hasPaidToRemoveAds = true
                }
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        guard NetworkUtility.internetReachable() else { return }
        guard SettingsController.sharedController.notificationsActive else { return }
        guard let lastPush = SettingsController.sharedController.lastPushDate else { return }
        guard NSDate().hoursFrom(lastPush) > SettingsController.sharedController.numberOfHoursPerNotification() else { return }

        NetworkUtility.networkOperationStarted()
        NetworkClient.sharedClient.getNotificationCountFromStartDate(lastPush) { count, error in
            NetworkUtility.networkOperationFinished()
            
            if let count = count where error == nil {
                self.postLocalNotificationWithNumberOfNewQuakes(lastPush, newQuakes: count)
            }
        }
    }
    
    internal func postLocalNotificationWithNumberOfNewQuakes(lastPush: NSDate, newQuakes: Int) {
        let hoursDifference = NSDate().hoursFrom(lastPush)
        
        SettingsController.sharedController.lastPushDate = NSDate()
        
        let partOne = newQuakes == 1 ? "A quake happened" : "\(newQuakes) quakes happened"
        var partTwo = ""
        if SettingsController.sharedController.notificationAmount == NotificationAmmount.NoLimit.rawValue ||
            SettingsController.sharedController.notificationAmount == NotificationAmmount.Hourly.rawValue {
                partTwo = hoursDifference == 1 ? "within the last hour." : "in the past \(hoursDifference) hours."
        }
        else if SettingsController.sharedController.notificationAmount == NotificationAmmount.Daily.rawValue {
            partTwo = " yesterday."
        }
        else {
            partTwo = " last week."
        }
        
        let notification = UILocalNotification()
        notification.alertBody = [partOne, partTwo].joinWithSeparator(" ")
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
}

