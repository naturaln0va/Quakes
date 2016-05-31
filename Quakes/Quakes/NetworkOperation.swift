
import UIKit

class NetworkOperation: NSOperation {
    enum State: String {
        case Ready, Executing, Finished
        
        private var keyPath: String {
            return "is" + rawValue
        }
    }
    
    private(set) var state = State.Ready {
        willSet {
            willChangeValueForKey(newValue.keyPath)
            willChangeValueForKey(state.keyPath)
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath)
            didChangeValueForKey(state.keyPath)
        }
    }
    
    var operating: Bool {
        return state != .Finished
    }
    
    var urlString: String { return "" } // Subclass to override
    var postParams: [String: AnyObject] { return [:] } // Subclass to override
    
    var debug = false
    let resultData = NSMutableData()
    
    private var sessionTask: NSURLSessionTask?
    private var internalURLSession: NSURLSession {
        return NSURLSession(configuration: internalConfig, delegate: self, delegateQueue: nil)
    }
    private var internalConfig: NSURLSessionConfiguration {
        return NSURLSessionConfiguration.defaultSessionConfiguration()
    }
    
    func handleData() {
        // Subclass to override
    }
}

//MARK: NSOperation Overrides
extension NetworkOperation {
    
    override var ready: Bool {
        return super.ready && state == .Ready
    }
    
    override var executing: Bool {
        return state == .Executing
    }
    
    override var finished: Bool {
        return state == .Finished
    }
    
    override var asynchronous: Bool {
        return true
    }
    
    override func start() {
        if cancelled {
            state = .Finished
            return
        }
        
        guard let url = NSURL(string: urlString) else { fatalError("\(self.dynamicType): Failed to build URL") }
        let request = NSMutableURLRequest(URL: url)
        
        if let jsonPostData = try? NSJSONSerialization.dataWithJSONObject(postParams, options: []) where NSJSONSerialization.isValidJSONObject(postParams) && postParams.count > 0 {
            request.HTTPMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("\(jsonPostData.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPBody = jsonPostData
        }
        
        sessionTask = internalURLSession.dataTaskWithRequest(request)
        sessionTask!.resume()
        
        state = .Executing
    }
    
    override func cancel() {
        sessionTask?.cancel()
        state = .Finished
    }
    
}

//MARK: NSURLSession Delegate
extension NetworkOperation: NSURLSessionDataDelegate {
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        if cancelled {
            state = .Finished
            sessionTask?.cancel()
            return
        }
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if debug { print("\(self.dynamicType): Code \(httpResponse.statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode))") }
            
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 404 {
                if debug { print("\(self.dynamicType): Canceling task because of the http status code, \(httpResponse.statusCode). Url: \(httpResponse.URL?.absoluteURL ?? "No URL")") }
                state = .Finished
                sessionTask?.cancel()
                completionHandler(.Cancel)
            }
        }
        
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if cancelled {
            state = .Finished
            sessionTask?.cancel()
            return
        }
        
        resultData.appendData(data)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if cancelled {
            state = .Finished
            sessionTask?.cancel()
            return
        }
        
        if debug && NSThread.isMainThread() { print("\(self.dynamicType): Completed on the main thread.") }
        
        if let e = error {
            if debug { print("\(self.dynamicType): Task completed with error: \(e.localizedDescription)") }
            state = .Finished
            return
        }
        
        handleData()
        state = .Finished
    }
    
}
