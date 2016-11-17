
import Foundation

class DownloadNearbyCitiesOperation: ConcurrentOperation {
    
    var urlString: String?
    var downloadedCities: [ParsedNearbyCity]?
    
    override func start() {
        if let detailProvider = dependencies
        .filter({ $0 is DetailDataProvider })
        .first as? DetailDataProvider, urlString == nil {
                urlString = detailProvider.urlString
        }
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            self.cancel()
            return
        }
        
        NetworkClient.sharedClient.getNearbyCitiesWithURL(urlForNearbyCities: url) { cities, error in
            guard let cities = cities, error == nil else {
                self.cancel()
                return
            }
            
            self.downloadedCities = cities
            self.state = .Finished
        }
    }
}
