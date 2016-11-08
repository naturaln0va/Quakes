
import Foundation
import CoreLocation

typealias DetailURLCompletionBlock = (_ urlString: String?, _ error: NSError?) -> Void
typealias NearbyCityCompletionBlock = (_ cities: [ParsedNearbyCity]?, _ error: NSError?) -> Void
typealias QuakesCompletionBlock = (_ quakes: [ParsedQuake]?, _ error: NSError?) -> Void
typealias CountCompletionBlock = (_ count: Int?, _ error: NSError?) -> Void
typealias ReciptCompletionBlock = (_ sucess: Bool) -> Void

class NetworkClient {
    static let sharedClient = NetworkClient()
    
    fileprivate lazy var requestsQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue(label: "io.ackermann.network", attributes: [])
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        return queue
    }()
    
    fileprivate let noResponseError = NSError(domain: "io.ackermann.network", code: 1539, userInfo: [NSLocalizedDescriptionKey: "No response from server"])
    
    func verifyInAppRecipt(_ completion: @escaping ReciptCompletionBlock) {
        guard let url = Bundle.main.appStoreReceiptURL else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        guard let receiptData = try? Data(contentsOf: url) else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        // testing: https://sandbox.itunes.apple.com/verifyReceipt
        // production: https://buy.itunes.apple.com/verifyReceipt
        guard let storeURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt") else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        let storeRequest = NSMutableURLRequest(url: storeURL)
        storeRequest.httpMethod = "POST"
        
        do {
            storeRequest.httpBody = try JSONSerialization.data(
                withJSONObject: ["receipt-data" : receiptData.base64EncodedString(options: [])],
                options: .prettyPrinted
            )
        }
        
        catch {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        NetworkUtility.networkOperationStarted()
        DispatchQueue(label: "io.ackermann.iap.verify", attributes: []).async {
//            URLSession.shared.dataTask(with: storeRequest, completionHandler: { data, response, error in
//                var success = false
//                
//                defer {
//                    NetworkUtility.networkOperationFinished()
//                    DispatchQueue.main.async {
//                        completion(sucess: success)
//                    }
//                }
//                
//                guard error == nil else { return }
//                guard let data = data else { return }
//                guard let receiptInfo = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: AnyObject] ?? [:] else { return }
//                
//                if let status = receiptInfo["status"] as? Int, status == 0 {
//                    success = true
//                }
//            }) .resume()
        }
    }
    
    func registerForNotificationsWithToken(_ token: String, location: CLLocation) {
        NetworkUtility.networkOperationStarted()
        let operation = AddDeviceOperation(
            token: token,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        operation.qualityOfService = .background
        operation.queuePriority = .normal
        
        operation.completionBlock = {
            NetworkUtility.networkOperationFinished()
        }
        
        requestsQueue.addOperation(operation)
    }
    
    func getNearbyCitiesWithURL(urlForNearbyCities url: URL, completion: @escaping NearbyCityCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = GetNearbyCitiesOperation(urlForNearbyCities: url)
        
        fetchOperation.qualityOfService = .background
        fetchOperation.queuePriority = .normal
        
        fetchOperation.completionBlock = { [weak self] in
            DispatchQueue.main.sync {
                NetworkUtility.networkOperationFinished()
                
                if let nearbyCities = fetchOperation.nearbyCities {
                    completion(nearbyCities, nil)
                }
                else {
                    completion(nil, self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getDetailForQuakeWithURL(urlForDetail url: URL, completion: @escaping DetailURLCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = GetDetailURLOperation(urlForDetail: url)
        
        fetchOperation.qualityOfService = .background
        fetchOperation.queuePriority = .normal
        
        fetchOperation.completionBlock = { [weak self] in
            DispatchQueue.main.sync {
                NetworkUtility.networkOperationFinished()
                
                if let detailURLString = fetchOperation.detailURLString {
                    completion(detailURLString, nil)
                }
                else {
                    completion(nil, self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
    func getQuakesByLocation(_ coordinate: CLLocationCoordinate2D, completion: QuakesCompletionBlock?) {
        NetworkUtility.networkOperationStarted()

        let USGSFetchOperation = USGSLocationOperation(coordinate: coordinate)
        USGSFetchOperation.qualityOfService = .userInitiated
        USGSFetchOperation.queuePriority = .veryHigh
        
        USGSFetchOperation.completionBlock = { [weak self] in
            DispatchQueue.main.sync {
                NetworkUtility.networkOperationFinished()
                SettingsController.sharedController.lastFetchDate = Date()
                
                if let recievedQuakes = USGSFetchOperation.quakes {
                    completion?(recievedQuakes, nil)
                }
                else {
                    completion?(nil, self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperations([USGSFetchOperation], waitUntilFinished: false)
    }
    
    func getMajorQuakes(_ completion: QuakesCompletionBlock?) {
        NetworkUtility.networkOperationStarted()
        
        let USGSFetchOperation = USGSMajorOperation()
        USGSFetchOperation.qualityOfService = .userInitiated
        USGSFetchOperation.queuePriority = .veryHigh
        
        USGSFetchOperation.completionBlock = { [weak self] in
            DispatchQueue.main.sync {
                NetworkUtility.networkOperationFinished()
                SettingsController.sharedController.lastFetchDate = Date()
                
                if let recievedQuakes = USGSFetchOperation.quakes {
                    completion?(recievedQuakes, nil)
                }
                else {
                    completion?(nil, self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperations([USGSFetchOperation], waitUntilFinished: false)
    }
    
    func getWorldQuakes(_ completion: QuakesCompletionBlock?) {
        NetworkUtility.networkOperationStarted()
        
        let USGSFetchOperation = USGSWorldOperation()
        USGSFetchOperation.qualityOfService = .userInitiated
        USGSFetchOperation.queuePriority = .veryHigh
        
        USGSFetchOperation.completionBlock = { [weak self] in
            DispatchQueue.main.sync {
                NetworkUtility.networkOperationFinished()
                SettingsController.sharedController.lastFetchDate = Date()
                
                if let recievedQuakes = USGSFetchOperation.quakes {
                    completion?(recievedQuakes, nil)
                }
                else {
                    completion?(nil, self?.noResponseError)
                }
            }
        }
        
        requestsQueue.addOperations([USGSFetchOperation], waitUntilFinished: false)
    }
    
    func getNotificationCountFromStartDate(_ startDate: Date, completion: CountCompletionBlock) {
        NetworkUtility.networkOperationStarted()
        let fetchOperation = RecentQuakeCountOperation()
        fetchOperation.qualityOfService = .background
        fetchOperation.queuePriority = .low
        
        fetchOperation.completionBlock = {
            DispatchQueue.main.sync {
                NetworkUtility.networkOperationFinished()
            }
        }
        
        requestsQueue.addOperation(fetchOperation)
    }
    
}
