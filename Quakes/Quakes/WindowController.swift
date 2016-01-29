

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
        
        // do this more intelligentlys
        application.registerUserNotificationSettings(UIUserNotificationSettings(
            forTypes: .Alert,
            categories: nil)
        )
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if let lastFetch = SettingsController.sharedController.lastFetchDate {
            let hoursDifference = NSDate().hoursFrom(lastFetch)
            guard hoursDifference > 0 else { completionHandler(.NoData); return }
            
            if let lastPlace = SettingsController.sharedController.lastSearchedPlace {
                NetworkUtility.networkOperationStarted()
                NetworkClient.sharedClient.getRecentQuakesByLocation(lastPlace.location!.coordinate, radius: SettingsController.sharedController.searchRadius.rawValue) { quakes, error in
                    NetworkUtility.networkOperationFinished()
                    
                    if let quakes = quakes where error == nil {
                        PersistentController.sharedController.saveQuakes(quakes) { newCount in
                            if newCount > 0 {
                                self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
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
                                    if newCount > 0 {
                                        self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
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
                                if newCount > 0 {
                                    self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
                                }
                            }
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
                                if newCount > 0 {
                                    self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
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
                    break
                }
            }
        }
    }
    
    internal func postLocalNotificationWithNumberOfNewQuakes(newQuakes: Int, lastFetched numberOfHoursAgo: Int) {
        let partOne = newQuakes == 1 ? "An quake happened" : "\(newQuakes) quakes happened"
        let partTwo = numberOfHoursAgo == 1 ? "an hour ago." : "\(numberOfHoursAgo) hours ago."
        
        let notification = UILocalNotification()
        notification.alertBody = [partOne, partTwo].joinWithSeparator(" ")
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }

}

