
import Foundation
import CoreLocation

typealias DetailURLCompletionBlock = (urlString: String?, error: NSError?) -> Void
typealias NearbyCityCompletionBlock = (cities: [ParsedNearbyCity]?, error: NSError?) -> Void
typealias QuakesCompletionBlock = (quakes: [ParsedQuake]?, error: NSError?) -> Void
typealias CountCompletionBlock = (count: Int?, error: NSError?) -> Void

let kNoResponseError = NSError(domain: "io.ackermann.NetworkClient", code: 10000, userInfo: [NSLocalizedDescriptionKey: "No response from server"])
let kJSONParseError = NSError(domain: "io.ackermann.NetworkClient", code: 10001, userInfo: [NSLocalizedDescriptionKey: "JSON parse error"])
let kInvalidDataError = NSError(domain: "io.ackermann.NetworkClient", code: 10002, userInfo: [NSLocalizedDescriptionKey: "Invalid data error"])

private let kUSGSAPIHost = "http://earthquake.usgs.gov/fdsnws/event/1/"

private let kQueryMethodName = "query"
private let kCountMethodName = "count"

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
    
    static func urlStringFromHostWithMethod(shouldLimit limit: Bool, method: String, parameters: [(String, String)]?) -> String
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
        
        SettingsController.sharedController.lastFetchDate = NSDate()
        
        if limit { urlString += "&\(ParamTypes.Limit.rawValue)=\(SettingsController.sharedController.fetchLimit.rawValue)" }
        
        return urlString
    }
    
    func getNearbyCitiesWithURL(urlForNearbyCities url: NSURL, completion: NearbyCityCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        dispatch_async(allRequestsQueue) {
            NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: url)) { data, response, error in
                var nearbyCities: [ParsedNearbyCity]?
                var resultError = error
                
                defer {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(cities: nearbyCities, error: resultError)
                    }
                }
                
                guard error == nil else { return }
                
                guard let data = data else {
                    resultError = kNoResponseError
                    return
                }
                
                var dicts: [[String: AnyObject]]?
                
                do {
                    dicts = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [[String: AnyObject]]
                } catch {
                    if DEBUG_REQUESTS { print("Error parsing JSON") }
                    resultError = kJSONParseError
                    return
                }
                
                guard let responseDicts = dicts else {
                    resultError = kInvalidDataError
                    return
                }
                
                if DEBUG_REQUESTS { print("Sent: \(response?.URL)\nReceived: \(responseDicts)") }

                nearbyCities = responseDicts.map {
                    return ParsedNearbyCity(dict: $0)
                }
                NetworkUtility.networkOperationFinished()
            }.resume()
        }

    }
    
    func getDetailForQuakeWithURL(urlForDetail url: NSURL, completion: DetailURLCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        dispatch_async(allRequestsQueue) {
            NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: url)) { data, response, error in
                var detailURLString: String?
                var resultError = error
                
                defer {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(urlString: detailURLString, error: resultError)
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
                
                if DEBUG_REQUESTS { print("Sent: \(response?.URL)\nReceived: \(responseDict)") }
                
                guard let firstDetailDict = ((responseDict as AnyObject).valueForKeyPath("properties.products.nearby-cities") as? [[String: AnyObject]])?.first else {
                    resultError = kInvalidDataError
                    return
                }
                
                guard let urlString = (((firstDetailDict as AnyObject).valueForKeyPath("contents") as? [String: AnyObject])?["nearby-cities.json"] as? [String: AnyObject])?["url"] as? String else {
                    resultError = kInvalidDataError
                    return
                }
                
                detailURLString = urlString
                NetworkUtility.networkOperationFinished()
            }.resume()
        }
    }
    
    func getRecentQuakesByLocation(coordinate: CLLocationCoordinate2D, radius: Int, completion: QuakesCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        dispatch_async(allRequestsQueue) {
            let params = [
                (FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue),
                (ParamTypes.LocationLatitude.rawValue, "\(coordinate.latitude)"),
                (ParamTypes.LocationLongitude.rawValue, "\(coordinate.longitude)"),
                (ParamTypes.LocationMaxRadiusKM.rawValue, "\(radius)")
            ]
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(shouldLimit: true, method: kQueryMethodName, parameters: params))!)
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
                
                if DEBUG_REQUESTS { print("Sent: \(request.URL)\nReceived: \(responseDict)") }
                
                guard let quakesDicts = responseDict["features"] as? [[String: AnyObject]] else {
                    resultError = kInvalidDataError
                    return
                }
                
                quakes = quakesDicts.flatMap{ ParsedQuake(dict: $0) }
                NetworkUtility.networkOperationFinished()
            }.resume()
        }
    }
    
    func getRecentMajorQuakes(completion: QuakesCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        dispatch_async(allRequestsQueue) {
            let params = [
                (FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue),
                (ParamTypes.MagnitudeMin.rawValue, "\(3.8)")
            ]
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(shouldLimit: true, method: kQueryMethodName, parameters: params))!)
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
                NetworkUtility.networkOperationFinished()
            }.resume()
        }
    }
    
    func getRecentWorldQuakes(completion: QuakesCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        dispatch_async(allRequestsQueue) {
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(shouldLimit: true, method: kQueryMethodName, parameters: [(FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue)]))!)
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
                NetworkUtility.networkOperationFinished()
            }.resume()
        }
    }
    
    func getNearbyCount(latitude: Double, longitude: Double, radius: Double, completion: CountCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        dispatch_async(allRequestsQueue) {
            let params = [
                (FormatParam.ParameterName.rawValue, FormatParam.GeoJsonValue.rawValue),
                (ParamTypes.LocationLatitude.rawValue, "\(latitude)"),
                (ParamTypes.LocationLongitude.rawValue, "\(longitude)"),
                (ParamTypes.LocationMaxRadiusKM.rawValue, "\(radius)")
            ]
            let request = NSURLRequest(URL: NSURL(string: NetworkClient.urlStringFromHostWithMethod(shouldLimit: true, method: kCountMethodName, parameters: params))!)
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
                NetworkUtility.networkOperationFinished()
            }.resume()
        }
    }
    
}