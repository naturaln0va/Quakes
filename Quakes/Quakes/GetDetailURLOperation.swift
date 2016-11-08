
import UIKit

class GetDetailURLOperation: NetworkOperation {
    
    var detailURLString: String?
    
    fileprivate let urlForDetail: URL
    
    override var urlString: String {
        return urlForDetail.absoluteString
    }
    
    init(urlForDetail url: URL) {
        urlForDetail = url
    }
    
    override func handleData() {
        var dict: Dictionary<String, AnyObject>?
        
        do {
            dict = try JSONSerialization.jsonObject(with: resultData as Data, options: .mutableLeaves) as? Dictionary<String, AnyObject>
        }
        catch let error {
            if debug { print("\(type(of: self)): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDict = dict else {
            return
        }
        
        guard let firstDetailDict = ((responseDict as AnyObject).value(forKeyPath: "properties.products.nearby-cities") as? [[String: AnyObject]])?.first else {
            return
        }
        
        guard let urlString = (((firstDetailDict as AnyObject).value(forKeyPath: "contents") as? [String: AnyObject])?["nearby-cities.json"] as? [String: AnyObject])?["url"] as? String else {
            return
        }
        
        if debug { print("\(type(of: self)): Sent: \(urlString)\nReceived: \(responseDict)") }
        
        detailURLString = urlString
    }
    
}
