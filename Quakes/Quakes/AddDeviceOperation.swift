
import UIKit

class AddDeviceOperation: NetworkOperation {
    
    let token: String
    let latitude: Double
    let longitude: Double
    
    init(token: String, latitude: Double, longitude: Double) {
        self.token = token
        self.latitude = latitude
        self.longitude = longitude
    }
    
    override var postParams: [String : AnyObject] {
        return [
            "token": token,
            "lat": latitude,
            "long": longitude
        ]
    }
    
    override var urlString: String {
        return "http://quakes.api.ackermann.io/add_user"
    }
    
    override func handleData() {
        var dict: [String: AnyObject]?
        
        do {
            dict = try NSJSONSerialization.JSONObjectWithData(incomingData, options: .MutableLeaves) as? [String: AnyObject]
        }
        catch let error {
            if shouldDebugOperation { print("\(self.dynamicType): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDict = dict else {
            return
        }
        
        if shouldDebugOperation { print("\(self.dynamicType): Sent: \(urlString)\nReceived: \(responseDict)") }
    }
    
}
