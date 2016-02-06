
import UIKit

protocol DetailDataProvider {
    var urlString: String? { get }
}

class DownloadDetailOperation: ConcurrentOperation
{
    private let url: NSURL
    var detailURLString: String?

    init(url: NSURL) {
        self.url = url
        super.init()
    }
    
    override func main() {
        NetworkClient.sharedClient.getDetailForQuakeWithURL(urlForDetail: url) { detailURLString, error in
            guard let detailURLString = detailURLString where error == nil else {
                self.cancel()
                return
            }
            
            self.detailURLString = detailURLString
            self.state = .Finished
        }
    }
}

extension DownloadDetailOperation: DetailDataProvider
{
    var urlString: String? { return detailURLString }
}
