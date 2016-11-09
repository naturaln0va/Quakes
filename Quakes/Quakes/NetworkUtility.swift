
import UIKit

class NetworkUtility {
    
    fileprivate static var loadingCount = 0
    
    static func networkOperationStarted() {
        if loadingCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        loadingCount += 1
    }
    
    static func networkOperationFinished() {
        if loadingCount > 0 {
            loadingCount -= 1
        }
        if loadingCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    static func internetReachable() -> Bool {
        if let reach = Reachability() {
            return reach.isReachable
        }
        else {
            return false
        }
    }
    
}
