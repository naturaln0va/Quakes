
import UIKit

class USGSWorldOperation: USGSFetchQuakesOperation {
    
    override var urlString: String {
        return "\(baseURLString)query?format=geojson&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
    }
    
}
