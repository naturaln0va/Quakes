
import UIKit

class GetDetailURLOperation: NetworkOperation {
    
    var detailURLString: String?
    
    private let urlForDetail: NSURL
    
    override var urlString: String {
        return urlForDetail.absoluteString
    }
    
    init(urlForDetail url: NSURL) {
        urlForDetail = url
    }
    
    override func handleData() {
        var dict: Dictionary<String, AnyObject>?
        
        do {
            dict = try NSJSONSerialization.JSONObjectWithData(resultData, options: .MutableLeaves) as? Dictionary<String, AnyObject>
        }
        catch let error {
            if debug { print("\(self.dynamicType): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDict = dict else {
            return
        }
        
        guard let firstDetailDict = ((responseDict as AnyObject).valueForKeyPath("properties.products.nearby-cities") as? [[String: AnyObject]])?.first else {
            return
        }
        
        guard let urlString = (((firstDetailDict as AnyObject).valueForKeyPath("contents") as? [String: AnyObject])?["nearby-cities.json"] as? [String: AnyObject])?["url"] as? String else {
            return
        }
        
        if debug { print("\(self.dynamicType): Sent: \(urlString)\nReceived: \(responseDict)") }
        
        detailURLString = urlString
    }
    
}
