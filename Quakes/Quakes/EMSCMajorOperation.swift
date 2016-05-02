
import UIKit

class EMSCMajorOperation: EMSCFetchQuakesOperation {
    
    override var urlString: String {
        return "\(baseURLString)query?limit=\(SettingsController.sharedController.fetchLimit.rawValue)&format=json&minmag=3.8"
    }
    
}
