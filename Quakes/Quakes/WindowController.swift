

import UIKit


@UIApplicationMain
class WindowController: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window.rootViewController = RecentViewController()
        window.makeKeyAndVisible()
        
        self.window = window
        
        return true
    }

}

