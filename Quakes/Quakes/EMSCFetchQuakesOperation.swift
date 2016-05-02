
import UIKit

class EMSCFetchQuakesOperation: NetworkOperation {
    
    let baseURLString = "http://www.seismicportal.eu/fdsnws/event/1/"
    var quakes: [ParsedQuake]?
    
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
        
        guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
            return
        }
        
        if shouldDebugOperation { print("\(self.dynamicType): Sent: \(urlString)\nReceived: \(quakesDicts)") }
        
        quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
    }
    
}
