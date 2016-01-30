

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
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if let lastPlace = SettingsController.sharedController.lastSearchedPlace {
            NetworkUtility.networkOperationStarted()
            NetworkClient.sharedClient.getRecentQuakesByLocation(lastPlace.location!.coordinate, radius: SettingsController.sharedController.searchRadius.rawValue) { quakes, error in
                NetworkUtility.networkOperationFinished()
                
                if let quakes = quakes where error == nil {
                    PersistentController.sharedController.saveQuakes(quakes) { newCount in
                        if newCount > 0 && SettingsController.sharedController.notificationType == NotificationType.Auto.rawValue {
                            self.postLocalNotificationWithNumberOfNewQuakes(newCount)
                        }
                    }
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
                if let currentLocation = SettingsController.sharedController.cachedAddress?.location {
                    NetworkUtility.networkOperationStarted()
                    NetworkClient.sharedClient.getRecentQuakesByLocation(currentLocation.coordinate, radius: SettingsController.sharedController.searchRadius.rawValue) { quakes, error in
                        NetworkUtility.networkOperationFinished()
                        
                        if let quakes = quakes where error == nil {
                            PersistentController.sharedController.saveQuakes(quakes) { newCount in
                                if newCount > 0 && SettingsController.sharedController.notificationType == NotificationType.Auto.rawValue || SettingsController.sharedController.notificationType == NotificationType.Nearby.rawValue {
                                    self.postLocalNotificationWithNumberOfNewQuakes(newCount)
                                }
                            }
                            completionHandler(.NewData)
                        }
                        else {
                            completionHandler(.Failed)
                        }
                    }
                }
                break
                
            case LocationOption.World.rawValue:
                NetworkUtility.networkOperationStarted()
                NetworkClient.sharedClient.getRecentWorldQuakes() { quakes, error in
                    NetworkUtility.networkOperationFinished()
                    
                    if let quakes = quakes where error == nil {
                        PersistentController.sharedController.saveQuakes(quakes) { newCount in
                            if newCount > 0 && SettingsController.sharedController.notificationType == NotificationType.Auto.rawValue || SettingsController.sharedController.notificationType == NotificationType.World.rawValue {
                                self.postLocalNotificationWithNumberOfNewQuakes(newCount)
                            }
                        }
                        PersistentController.sharedController.saveWorldQuakes(quakes)
                        completionHandler(.NewData)
                    }
                    else {
                        completionHandler(.Failed)
                    }
                }
                break
                
            case LocationOption.Major.rawValue:
                NetworkUtility.networkOperationStarted()
                NetworkClient.sharedClient.getRecentMajorQuakes { quakes, error in
                    NetworkUtility.networkOperationFinished()
                    
                    if let quakes = quakes where error == nil {
                        PersistentController.sharedController.saveQuakes(quakes) { newCount in
                            if newCount > 0 && SettingsController.sharedController.notificationType == NotificationType.Auto.rawValue || SettingsController.sharedController.notificationType == NotificationType.Major.rawValue {
                                self.postLocalNotificationWithNumberOfNewQuakes(newCount)
                            }
                        }
                        completionHandler(.NewData)
                    }
                    else {
                        completionHandler(.Failed)
                    }
                }
                break
                
            default:
                print("WARNING: Invalid option stored in 'SettingsController'.")
                completionHandler(.Failed)
                break
            }
        }
    }
    
    internal func postLocalNotificationWithNumberOfNewQuakes(newQuakes: Int) {
        guard SettingsController.sharedController.notificationsActive else { return }
        guard let lastPush = SettingsController.sharedController.lastPushDate else { return }
        
        let hoursDifference = NSDate().hoursFrom(lastPush)
        guard hoursDifference > SettingsController.sharedController.numberOfHoursPerNotification() else { return }
        
        SettingsController.sharedController.lastPushDate = NSDate()
        
        let partOne = newQuakes == 1 ? "A quake happened" : "\(newQuakes) quakes happened"
        let partTwo = (SettingsController.sharedController.notificationAmount == NotificationAmmount.NoLimit.rawValue || SettingsController.sharedController.notificationAmount == NotificationAmmount.Hourly.rawValue) ? (hoursDifference == 1 ? "within the last hour." : "in the past \(hoursDifference) hours.") : (SettingsController.sharedController.notificationAmount == NotificationAmmount.Weekly.rawValue ? " this week." : " today.")
        
        let notification = UILocalNotification()
        notification.alertBody = [partOne, partTwo].joinWithSeparator(" ")
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
}

