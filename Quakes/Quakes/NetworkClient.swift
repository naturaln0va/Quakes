
import Foundation

//typealias QuakesCompletionBlock = (video: BibleVideo?, error: NSError?) -> Void

let kNoResponseError = NSError(domain: "io.ackermann.NetworkClient", code: 10000, userInfo: [NSLocalizedDescriptionKey: "No response from server"])
let kJSONParseError = NSError(domain: "io.ackermann.NetworkClient", code: 10001, userInfo: [NSLocalizedDescriptionKey: "JSON parse error"])
let kInvalidDataError = NSError(domain: "io.ackermann.NetworkClient", code: 10002, userInfo: [NSLocalizedDescriptionKey: "Invalid data error"])

private let kUSGSAPIHost = "http://earthquake.usgs.gov/fdsnws/event/1/"

private let kQueryMethodName = "query"
private let kCountMethodName = "count"

private let kResponseDataKeyPath = "response.data"
private let DEBUG_REQUESTS = false

class NetworkClient
{
    
    static let sharedClient = NetworkClient()
    
    private let allRequestsQueue = dispatch_queue_create("io.ackermann.network", nil)
    
    private enum FormatParam: String {
        case ParameterName = "format"
        case CsvValue = "csv"
        case GeoJsonValue = "geojson"
        case KmlValue = "kml"
        case QuakemlValue = "quakeml"
        case TextValue = "text"
        case XmlValue = "xml"
    }
    
    static func urlStringFromHostWithMethod(method: String, parameters: [(String, String)]?) -> String
    {
        var urlString = kUSGSAPIHost
        
        urlString += method
        
        if let parameters = parameters {
            urlString += "?"
            var paramString = ""
            for param in parameters {
                if paramString.characters.count > 0 {
                    paramString += "&"
                }
                paramString += "\(param.0)=\(param.1)"
            }
            urlString += paramString
        }
        
        return urlString
    }
    
    func getRecentQuakes() {
        dispatch_async(allRequestsQueue) {
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(kQueryMethodName, parameters: [(FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue)]))!)
            NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
//                var versions: [BibleVersion]?
                var resultError = error
                
//                defer {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        completion(versions: versions, error: resultError)
//                    }
//                }
                
                guard error == nil else { return }
                
                guard let data = data else {
                    resultError = kNoResponseError
                    return
                }
                
                var dict: Dictionary<String, AnyObject>?
                
                do {
                    dict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? Dictionary<String, AnyObject>
                } catch {
                    if DEBUG_REQUESTS { print("Error parsing JSON") }
                    resultError = kJSONParseError
                    return
                }
                
                print("Sent: \(request.URL)\nReceived: \n\n\(dict)")
                
                guard let responseDict = dict else {
                    resultError = kInvalidDataError
                    return
                }
                
                guard let objectDict = (responseDict as AnyObject).valueForKeyPath("response.data.versions") as? [Dictionary<String, AnyObject>] else {
                    resultError = kInvalidDataError
                    return
                }
                
                if DEBUG_REQUESTS { print("Sent: \(request.URL)\nReceived: \n\n\(responseDict)") }
                
//                versions = objectDict.map { versionDict in
//                    return BibleVersion(dict: versionDict)
//                }
            }.resume()
        }
    }
}