
import UIKit

class EMSCWorldOperation: EMSCFetchQuakesOperation {
    
    override var urlString: String {
        return "\(baseURLString)query?limit=\(SettingsController.sharedController.fetchLimit.rawValue)&format=json"
    }
    
}
