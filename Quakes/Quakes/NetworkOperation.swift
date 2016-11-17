
import UIKit

class NetworkOperation: Operation {
    
    enum State: String {
        case Ready, Executing, Finished
        
        fileprivate var keyPath: String {
            return "is" + rawValue
        }
    }
    
    fileprivate(set) var state = State.Ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    var operating: Bool {
        return state != .Finished
    }
    
    var urlString: String { return "" } // Subclass to override
    var postParams: [String: AnyObject] { return [:] } // Subclass to override
    
    var debug = false
    let resultData = NSMutableData()
    
    fileprivate var sessionTask: URLSessionTask?
    fileprivate var internalURLSession: Foundation.URLSession {
        return Foundation.URLSession(configuration: internalConfig, delegate: self, delegateQueue: nil)
    }
    fileprivate var internalConfig: URLSessionConfiguration {
        return URLSessionConfiguration.default
    }
    
    func handleData() {
        // Subclass to override
    }
}

//MARK: NSOperation Overrides
extension NetworkOperation {
    
    override var isReady: Bool {
        return super.isReady && state == .Ready
    }
    
    override var isExecuting: Bool {
        return state == .Executing
    }
    
    override var isFinished: Bool {
        return state == .Finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if isCancelled {
            state = .Finished
            return
        }
        
        guard let url = URL(string: urlString) else { fatalError("\(type(of: self)): Failed to build URL") }
        var request = URLRequest(url: url)
        
        if let jsonPostData = try? JSONSerialization.data(withJSONObject: postParams, options: []), JSONSerialization.isValidJSONObject(postParams) && postParams.count > 0 {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("\(jsonPostData.count)", forHTTPHeaderField: "Content-Length")
            request.httpBody = jsonPostData
            
            if debug { print("Headers: \(request.allHTTPHeaderFields)") }
            if debug { print("Post Body: \(postParams)") }
        }
        
        sessionTask = internalURLSession.dataTask(with: request)
        sessionTask!.resume()
        
        state = .Executing
    }
    
    override func cancel() {
        sessionTask?.cancel()
        state = .Finished
    }
    
}

//MARK: NSURLSession Delegate
extension NetworkOperation: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if isCancelled {
            state = .Finished
            sessionTask?.cancel()
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if debug { print("\(type(of: self)): Code \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))") }
            
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 404 {
                if debug { print("\(type(of: self)): Canceling task because of the http status code, \(httpResponse.statusCode). Url: \(httpResponse.url?.absoluteString ?? "No URL")") }
                state = .Finished
                sessionTask?.cancel()
                completionHandler(.cancel)
            }
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if isCancelled {
            state = .Finished
            sessionTask?.cancel()
            return
        }
        
        resultData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if isCancelled {
            state = .Finished
            sessionTask?.cancel()
            return
        }
        
        if debug && Thread.isMainThread { print("\(type(of: self)): Completed on the main thread.") }
        
        if let e = error {
            if debug { print("\(type(of: self)): Task completed with error: \(e.localizedDescription)") }
            state = .Finished
            return
        }
        
        handleData()
        state = .Finished
    }
    
}
