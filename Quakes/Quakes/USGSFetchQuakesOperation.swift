
import UIKit

class USGSFetchQuakesOperation: NetworkOperation {
    
    let baseURLString = "http://earthquake.usgs.gov/fdsnws/event/1/"
    var quakes: [ParsedQuake]?
    
    override func handleData() {
        var dict: [String: AnyObject]?
        
        do {
            dict = try NSJSONSerialization.JSONObjectWithData(resultData, options: .MutableLeaves) as? [String: AnyObject]
        }
        catch let error {
            if debug { print("\(self.dynamicType): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDict = dict else {
            return
        }
        
        if debug { print("\(self.dynamicType): Sent: \(urlString)\nReceived: \(responseDict)") }
        
        guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
            return
        }
        
        quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
    }
    
}
