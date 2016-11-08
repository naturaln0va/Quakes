
import UIKit

class EMSCFetchQuakesOperation: NetworkOperation {
    
    let baseURLString = "http://www.seismicportal.eu/fdsnws/event/1/"
    var quakes: [ParsedQuake]?
    
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
        
        guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
            return
        }
        
        if debug { print("\(type(of: self)): Sent: \(urlString)\nReceived: \(quakesDicts)") }
        
        quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
    }
    
}
