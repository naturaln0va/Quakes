
import UIKit

class USGSMajorOperation: USGSFetchQuakesOperation {
    
    override var urlString: String {
        return "\(baseURLString)query?format=geojson&minmagnitude=3.8&limit=\(SettingsController.sharedController.fetchLimit.rawValue)"
    }
    
}
