
import UIKit


class NetworkUtility
{
    
    private static var loadingCount = 0
    
    static func networkOperationStarted() {
        if loadingCount == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
        loadingCount += 1
    }
    
    static func networkOperationFinished() {
        if loadingCount > 0 {
            loadingCount -= 1
        }
        if loadingCount == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    static func cancelCurrentNetworkRequests() {
        guard loadingCount > 0 else { return }
        loadingCount = 0
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        NSURLSession.sharedSession().invalidateAndCancel()
    }
    
    static func internetReachable() -> Bool {
        if let reach = try? Reachability.reachabilityForInternetConnection() {
            return reach.isReachable()
        }
        else {
            return false
        }
    }
    
}