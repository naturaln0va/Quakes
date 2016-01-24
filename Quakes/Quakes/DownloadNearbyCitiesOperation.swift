
import Foundation

class DownloadNearbyCitiesOperation: ConcurrentOperation
{
    var urlString: String?
    var downloadedCities: [ParsedNearbyCity]?
    
    override func start() {
        if let detailProvider = dependencies
        .filter({ $0 is DetailDataProvider })
        .first as? DetailDataProvider
            where urlString == nil {
                urlString = detailProvider.urlString
        }
        
        guard let urlString = urlString, let url = NSURL(string: urlString) else {
            self.cancel()
            return
        }
        
        NetworkClient.sharedClient.getNearbyCitiesWithURL(urlForNearbyCities: url) { cities, error in
            guard let cities = cities where error == nil else {
                self.cancel()
                return
            }
            
            self.downloadedCities = cities
            self.state = .Finished
        }
    }
}
