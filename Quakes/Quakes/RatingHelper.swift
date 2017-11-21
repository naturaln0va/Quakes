
import StoreKit

class RatingHelper {
    
    enum ActionKey: String {
        case share
        case detailView
        case locationChange
    }
    
    private enum RatingKey: String {
        case appLaunch
        case didPrompt
    }

    private static let minAppLaunches = 3
    private static let targetActionCount = 3
    
    class func incrementAppLaunch() {
        let defaults = UserDefaults.standard
        let launches = defaults.integer(forKey: RatingKey.appLaunch.rawValue)
        defaults.set(launches + 1, forKey: RatingKey.appLaunch.rawValue)
        defaults.synchronize()
    }
    
    class func incrementAction(for key: ActionKey) {
        let defaults = UserDefaults.standard
        
        let count = defaults.integer(forKey: key.rawValue) + 1
        let launches = defaults.integer(forKey: RatingKey.appLaunch.rawValue)
        let didPrompt = defaults.bool(forKey: RatingKey.didPrompt.rawValue)
        
        if count == targetActionCount && launches > minAppLaunches && !didPrompt {
            defaults.set(true, forKey: RatingKey.didPrompt.rawValue)
            SKStoreReviewController.requestReview()
        }
        
        defaults.set(count, forKey: key.rawValue)
        defaults.synchronize()
    }
    
}
