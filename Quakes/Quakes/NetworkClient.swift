
import Foundation
import CoreLocation

typealias QuakesCompletionBlock = (quakes: [ParsedQuake]?, error: NSError?) -> Void
typealias CountCompletionBlock = (count: Int?, error: NSError?) -> Void

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
    
    private enum ParamTypes: String {
        case LocationLatitude = "latitude"
        case LocationLongitude = "longitude"
        case LocationMaxRadiusKM = "maxradiuskm"
        case MagnitudeMin = "minmagnitude"
        case Limit = "limit"
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
        
        urlString += "&\(ParamTypes.Limit.rawValue)=\(125)"
        
        return urlString
    }
    
    func getRecentQuakesByLocation(coordinate: CLLocationCoordinate2D, radius: Double, completion: QuakesCompletionBlock) {
        dispatch_async(allRequestsQueue) {
            let params = [
                (FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue),
                (ParamTypes.LocationLatitude.rawValue, "\(coordinate.latitude)"),
                (ParamTypes.LocationLongitude.rawValue, "\(coordinate.longitude)"),
                (ParamTypes.LocationMaxRadiusKM.rawValue, "\(radius)")
            ]
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(kQueryMethodName, parameters: params))!)
            NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                var quakes: [ParsedQuake]?
                var resultError = error
                
                defer {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(quakes: quakes, error: error)
                    }
                }
                
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
                
                guard let responseDict = dict else {
                    resultError = kInvalidDataError
                    return
                }
                
                guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
                    resultError = kInvalidDataError
                    return
                }
                
                if DEBUG_REQUESTS { print("Sent: \(request.URL)\nReceived: \(responseDict)") }
                
                quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
                
            }.resume()
        }
    }
    
    func getRecentMajorQuakes(completion: QuakesCompletionBlock) {
        dispatch_async(allRequestsQueue) {
            let params = [
                (FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue),
                (ParamTypes.MagnitudeMin.rawValue, "\(3.8)")
            ]
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(kQueryMethodName, parameters: params))!)
            NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                var quakes: [ParsedQuake]?
                var resultError = error
                
                defer {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(quakes: quakes, error: error)
                    }
                }
                
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
                
                guard let responseDict = dict else {
                    resultError = kInvalidDataError
                    return
                }
                
                guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
                    resultError = kInvalidDataError
                    return
                }
                
                if DEBUG_REQUESTS { print("Sent: \(request.URL)\nReceived: \(responseDict)") }
                
                quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
                
            }.resume()
        }
    }
    
    func getRecentWorldQuakes(completion: QuakesCompletionBlock) {
        dispatch_async(allRequestsQueue) {
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(kQueryMethodName, parameters: [(FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue)]))!)
            NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                var quakes: [ParsedQuake]?
                var resultError = error
                
                defer {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(quakes: quakes, error: error)
                    }
                }
                
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
                
                guard let responseDict = dict else {
                    resultError = kInvalidDataError
                    return
                }
                
                guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
                    resultError = kInvalidDataError
                    return
                }
                
                if DEBUG_REQUESTS { print("Sent: \(request.URL)\nReceived: \(responseDict)") }
                
                quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
                
            }.resume()
        }
    }
    
    func getNearbyCount(latitude: Double, longitude: Double, radius: Double, completion: CountCompletionBlock) {
        dispatch_async(allRequestsQueue) {
            let params = [
                (FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue),
                (ParamTypes.LocationLatitude.rawValue, "\(latitude)"),
                (ParamTypes.LocationLongitude.rawValue, "\(longitude)"),
                (ParamTypes.LocationMaxRadiusKM.rawValue, "\(radius)")
            ]
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(kCountMethodName, parameters: params))!)
            NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                var count: Int?
                var resultError = error
                
                defer {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(count: count, error: error)
                    }
                }
                
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
                
                guard let responseDict = dict else {
                    resultError = kInvalidDataError
                    return
                }
                
                guard let quakeCount = responseDict["count"] as? Int else {
                    resultError = kInvalidDataError
                    return
                }
                
                if DEBUG_REQUESTS { print("Sent: \(request.URL)\nReceived: \(responseDict)") }
                
                count = quakeCount
            }.resume()
        }
    }
    
}