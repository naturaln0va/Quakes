
import UIKit

class GetNearbyCitiesOperation: NetworkOperation {
    
    var nearbyCities: [ParsedNearbyCity]?
    
    fileprivate let urlForNearbyCities: URL
    
    override var urlString: String {
        return urlForNearbyCities.absoluteString
    }
    
    init(urlForNearbyCities url: URL) {
        urlForNearbyCities = url
    }
    
    override func handleData() {
        var dicts: [[String: AnyObject]]?
        
        do {
            dicts = try JSONSerialization.jsonObject(with: resultData as Data, options: .mutableLeaves) as? [[String: AnyObject]]
        }
        catch let error {
            if debug { print("\(type(of: self)): Error parsing JSON. Error: \(error)") }
            return
        }
        
        guard let responseDicts = dicts else {
            return
        }
        
        if debug { print("\(type(of: self)): Sent: \(urlString)\nReceived: \(responseDicts)") }
        
        nearbyCities = responseDicts.map {
            return ParsedNearbyCity(dict: $0)
        }
    }
    
}
