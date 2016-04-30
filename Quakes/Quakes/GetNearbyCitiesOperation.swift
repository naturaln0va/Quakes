
import UIKit

class GetNearbyCitiesOperation: NetworkOperation {
    
    var nearbyCities: [ParsedNearbyCity]?
    
    private let urlForNearbyCities: NSURL
    
    override var urlString: String {
        return urlForNearbyCities.absoluteString
    }
    
    init(urlForNearbyCities url: NSURL) {
        urlForNearbyCities = url
    }
    
    override func handleData() {
        var dicts: [[String: AnyObject]]?
        
        do {
            dicts = try NSJSONSerialization.JSONObjectWithData(incomingData, options: .MutableLeaves) as? [[String: AnyObject]]
        }
        catch let error {
            if shouldDebugOperation { print("\(self.dynamicType): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDicts = dicts else {
            return
        }
        
        if shouldDebugOperation { print("\(self.dynamicType): Sent: \(urlString)\nReceived: \(responseDicts)") }
        
        nearbyCities = responseDicts.map {
            return ParsedNearbyCity(dict: $0)
        }
    }
    
}
