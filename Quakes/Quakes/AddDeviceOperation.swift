
import UIKit

class AddDeviceOperation: NetworkOperation {
    
    let token: String
    let latitude: Double
    let longitude: Double
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumSignificantDigits = 7
        return formatter
    }()
    
    init(token: String, latitude: Double, longitude: Double) {
        self.token = token
        self.latitude = latitude
        self.longitude = longitude
    }
    
    override var postParams: [String : AnyObject] {
        return [
            "token": token as AnyObject,
            "lat": numberFormatter.string(from: NSNumber(value: latitude as Double))! as AnyObject,
            "long": numberFormatter.string(from: NSNumber(value: longitude as Double))! as AnyObject
        ]
    }
    
    override var urlString: String {
        return "http://quakes.api.ackermann.io/add_user"
    }
    
    override func handleData() {
        var dict: [String: AnyObject]?
        
        do {
            dict = try JSONSerialization.jsonObject(with: resultData as Data, options: .mutableLeaves) as? [String: AnyObject]
        }
        catch let error {
            if debug { print("\(type(of: self)): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDict = dict else {
            return
        }
        
        if debug { print("\(type(of: self)): Sent: \(urlString)\nReceived: \(responseDict)") }
    }
    
}
