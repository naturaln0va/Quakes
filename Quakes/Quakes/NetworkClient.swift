
import Foundation
import CoreLocation

typealias DetailURLCompletionBlock = (urlString: String?, error: NSError?) -> Void
typealias NearbyCityCompletionBlock = (cities: [ParsedNearbyCity]?, error: NSError?) -> Void
typealias QuakesCompletionBlock = (quakes: [ParsedQuake]?, error: NSError?) -> Void
typealias CountCompletionBlock = (count: Int?, error: NSError?) -> Void
typealias ReciptCompletionBlock = (sucess: Bool) -> Void

class NetworkClient {
    static let sharedClient = NetworkClient()
    
    private lazy var requestsQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.underlyingQueue = dispatch_queue_create("io.ackermann.network", nil)
        return queue
    }()
    
    private let noResponseError = NSError(domain: "io.ackermann.network", code: 1539, userInfo: [NSLocalizedDescriptionKey: "No response from server"])
    
    func verifyInAppRecipt(completion: ReciptCompletionBlock) {
        guard let url = NSBundle.mainBundle().appStoreReceiptURL else {
            dispatch_async(dispatch_get_main_queue()) {
                completion(sucess: false)
            }
            return
        }
        
        guard let receiptData = NSData(contentsOfURL: url) else {
            dispatch_async(dispatch_get_main_queue()) {
                completion(sucess: false)
            }
            return
        }
        
        // testing: https://sandbox.itunes.apple.com/verifyReceipt
        // production: https://buy.itunes.apple.com/verifyReceipt
        guard let storeURL = NSURL(string: "https://buy.itunes.apple.com/verifyReceipt") else {
            dispatch_async(dispatch_get_main_queue()) {
                completion(sucess: false)
            }
            return
        }
        
        let storeRequest = NSMutableURLRequest(URL: storeURL)
        storeRequest.HTTPMethod = "POST"
        
        do {
            storeRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(
                ["receipt-data" : receiptData.base64EncodedStringWithOptions([])],
                options: .PrettyPrinted
            )
        }
        
        catch {
            dispatch_async(dispatch_get_main_queue()) {
                completion(sucess: false)
            }
            return
        }
        
        NetworkUtility.networkOperationStarted()
        dispatch_async(dispatch_queue_create("io.ackermann.iap.verify", nil)) {
            NSURLSession.sharedSession().dataTaskWithRequest(storeRequest) { data, response, error in
                var success = false
                
                defer {
                    NetworkUtility.networkOperationFinished()
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(sucess: success)
                    }
                }
                
                guard error == nil else { return }
                guard let data = data else { return }
                guard let receiptInfo = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [String: AnyObject] ?? [:] else { return }
                
                if let status = receiptInfo["status"] as? Int where status == 0 {
                    success = true
                }
            }.resume()
        }
    }
    
    func getNearbyCitiesWithURL(urlForNearbyCities url: NSURL, completion: NearbyCityCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = GetNearbyCitiesOperation(urlForNearbyCities: url)
        
        fetchOperation.qualityOfService = .Background
        fetchOperation.queuePriority = .Normal
        
        fetchOperation.completionBlock = { [weak self] in
            dispatch_sync(dispatch_get_main_queue()) {
                NetworkUtility.networkOperationFinished()
                
                if let nearbyCities = fetchOperation.nearbyCities {
                    completion(cities: nearbyCities, error: nil)
                }
                else {
                    completion(cities: nil, error: self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getDetailForQuakeWithURL(urlForDetail url: NSURL, completion: DetailURLCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = GetDetailURLOperation(urlForDetail: url)
        
        fetchOperation.qualityOfService = .Background
        fetchOperation.queuePriority = .Normal
        
        fetchOperation.completionBlock = { [weak self] in
            dispatch_sync(dispatch_get_main_queue()) {
                NetworkUtility.networkOperationFinished()
                
                if let detailURLString = fetchOperation.detailURLString {
                    completion(urlString: detailURLString, error: nil)
                }
                else {
                    completion(urlString: nil, error: self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getQuakesByLocation(coordinate: CLLocationCoordinate2D, completion: QuakesCompletionBlock?) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = USGSLocationOperation(coordinate: coordinate)
        fetchOperation.qualityOfService = .UserInitiated
        fetchOperation.queuePriority = .VeryHigh
        
        fetchOperation.completionBlock = { [weak self] in
            dispatch_sync(dispatch_get_main_queue()) {
                NetworkUtility.networkOperationFinished()
                SettingsController.sharedController.lastFetchDate = NSDate()
                
                if let recievedQuakes = fetchOperation.quakes {
                    PersistentController.sharedController.saveQuakes(recievedQuakes)
                    completion?(quakes: recievedQuakes, error: nil)
                }
                else {
                    completion?(quakes: nil, error: self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getMajorQuakes(completion: QuakesCompletionBlock?) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = USGSMajorOperation()
        fetchOperation.qualityOfService = .UserInitiated
        fetchOperation.queuePriority = .VeryHigh
        
        fetchOperation.completionBlock = { [weak self] in
            dispatch_sync(dispatch_get_main_queue()) {
                NetworkUtility.networkOperationFinished()
                SettingsController.sharedController.lastFetchDate = NSDate()
                
                if let recievedQuakes = fetchOperation.quakes {
                    PersistentController.sharedController.saveQuakes(recievedQuakes)
                    completion?(quakes: recievedQuakes, error: nil)
                }
                else {
                    completion?(quakes: nil, error: self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getWorldQuakes(completion: QuakesCompletionBlock?) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = USGSWorldOperation()
        fetchOperation.qualityOfService = .UserInitiated
        fetchOperation.queuePriority = .VeryHigh
        
        fetchOperation.completionBlock = { [weak self] in
            dispatch_sync(dispatch_get_main_queue()) {
                NetworkUtility.networkOperationFinished()
                SettingsController.sharedController.lastFetchDate = NSDate()
                
                if let recievedQuakes = fetchOperation.quakes {
                    PersistentController.sharedController.saveQuakes(recievedQuakes)
                    completion?(quakes: recievedQuakes, error: nil)
                }
                else {
                    completion?(quakes: nil, error: self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getNotificationCountFromStartDate(startDate: NSDate, completion: CountCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = RecentQuakeCountOperation()
        fetchOperation.qualityOfService = .Background
        fetchOperation.queuePriority = .Low
        
        fetchOperation.completionBlock = {
            dispatch_sync(dispatch_get_main_queue()) {
                NetworkUtility.networkOperationFinished()
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
}