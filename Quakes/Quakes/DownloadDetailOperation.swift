
import UIKit

protocol DetailDataProvider {
    var urlString: String? { get }
}

class DownloadDetailOperation: ConcurrentOperation {
    
    fileprivate let url: URL
    var detailURLString: String?

    init(url: URL) {
        self.url = url
        super.init()
    }
    
    override func main() {
        NetworkClient.sharedClient.getDetailForQuakeWithURL(urlForDetail: url) { detailURLString, error in
            guard let detailURLString = detailURLString, error == nil else {
                self.cancel()
                return
            }
            
            self.detailURLString = detailURLString
            self.state = .Finished
        }
    }
    
}

extension DownloadDetailOperation: DetailDataProvider {
    
    var urlString: String? { return detailURLString }
    
}
