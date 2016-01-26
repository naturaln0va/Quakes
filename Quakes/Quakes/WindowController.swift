

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
        
        // do this more intelligently
        application.registerUserNotificationSettings(UIUserNotificationSettings(
            forTypes: .Alert,
            categories: nil)
        )
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if let lastFetch = SettingsController.sharedController.lastFetchDate {
            let hoursDifference = lastFetch.hoursFrom(NSDate())
            guard hoursDifference > 0 else { return }
            
            if let lastPlace = SettingsController.sharedController.lastSearchedPlace {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                NetworkClient.sharedClient.getRecentQuakesByLocation(lastPlace.location!.coordinate, radius: SettingsController.sharedController.searchRadius.rawValue) { quakes, error in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if let quakes = quakes where error == nil {
                        PersistentController.sharedController.saveQuakes(quakes) { newCount in
                            if newCount > 0 {
                                self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
                            }
                        }
                    }
                }
                return
            }
            
            if let option = SettingsController.sharedController.lastLocationOption {
                switch option {
                case LocationOption.Nearby.rawValue:
                    if let currentLocation = SettingsController.sharedController.cachedAddress?.location {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                        NetworkClient.sharedClient.getRecentQuakesByLocation(currentLocation.coordinate, radius: SettingsController.sharedController.searchRadius.rawValue) { quakes, error in
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            
                            if let quakes = quakes where error == nil {
                                PersistentController.sharedController.saveQuakes(quakes) { newCount in
                                    if newCount > 0 {
                                        self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
                                    }
                                }
                            }
                        }
                    }
                    break
                case LocationOption.World.rawValue:
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    NetworkClient.sharedClient.getRecentWorldQuakes() { quakes, error in
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        if let quakes = quakes where error == nil {
                            PersistentController.sharedController.saveQuakes(quakes) { newCount in
                                if newCount > 0 {
                                    self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
                                }
                            }
                        }
                    }
                    break
                case LocationOption.Major.rawValue:
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    NetworkClient.sharedClient.getRecentMajorQuakes { quakes, error in
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        if let quakes = quakes where error == nil {
                            PersistentController.sharedController.saveQuakes(quakes) { newCount in
                                if newCount > 0 {
                                    self.postLocalNotificationWithNumberOfNewQuakes(newCount, lastFetched: hoursDifference)
                                }
                            }
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

