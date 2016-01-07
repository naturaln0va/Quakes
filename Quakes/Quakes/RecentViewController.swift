
import UIKit
import CoreData
import CoreLocation


class RecentViewController: UIViewController
{
    
    @IBOutlet var tableView: UITableView!
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.moc
        
        let fetchRequest = Quake.fetchRequest(moc, predicate: nil, sortedBy: "timestamp", ascending: false)
        fetchRequest.fetchBatchSize = 20
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "quakes")
    }()
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        return manager
    }()
    private lazy var titleViewButton: UIButton = {
        let button = UIButton(type: .Custom)
        
        button.backgroundColor = UIColor(white: 0.0, alpha: 0.25)
        button.titleLabel?.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        button.setTitleColor(StyleController.contrastColor, forState: .Normal)
        button.addTarget(self, action: "titleButtonPressed", forControlEvents: .TouchUpInside)
        button.setTitle("Locating...", forState: .Normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 4.0
        button.sizeToFit()
        
        return button
    }()
    let refreshControl = UIRefreshControl()
    var currentLocation: CLLocation?
    var currentAddress: CLPlacemark?
    let geocoder = CLGeocoder()

    deinit {
        fetchedResultsController.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = titleViewButton
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = QuakeCell.cellHeight
        tableView.backgroundColor = StyleController.mainAppColor
        tableView.registerNib(UINib(nibName: QuakeCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: QuakeCell.reuseIdentifier)
        
        refreshControl.tintColor = StyleController.contrastColor
        refreshControl.backgroundColor = StyleController.mainAppColor
        refreshControl.addTarget(self, action: "handleRefresh", forControlEvents: .ValueChanged)
        
        fetchedResultsController.delegate = self
        preformFetch()
        
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedWhenInUse:
            locationManager.requestLocation()
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    private func preformFetch()
    {
        do {
            try fetchedResultsController.performFetch()
        }
            
        catch {
            print("Error fetching for the results controller: \(error)")
        }
    }
    
    func titleButtonPressed() {
        print("Title button was pressed")
    }
    
    func handleRefresh()
    {
        if !refreshControl.refreshing {
            refreshControl.beginRefreshing()
        }
        
        if let location = currentLocation {
            NetworkClient.sharedClient.getNearbyRecentQuakes(location.coordinate.latitude, longitude: location.coordinate.longitude, radius: 150.0) { quakes, error in
                if let quakes = quakes where error == nil {
                    for quake in quakes {
                        PersistentController.sharedController.saveQuake(quake)
                    }
                    self.tableView.reloadData()
                    if self.refreshControl.refreshing {
                        self.refreshControl.endRefreshing()
                    }
                }
            }
        }
        else {
            print("Tried to fetch quakes without a location.")
        }
    }
    
}

extension RecentViewController: CLLocationManagerDelegate
{
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        }
        else {
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
//            NetworkClient.sharedClient.getNearbyCount(
//                lastLocation.coordinate.latitude,
//                longitude: lastLocation.coordinate.longitude,
//                radius: 450.0,
//                completion: { count, error in
//                    if let _ = count where error == nil {
//                    }
//                }
//            )
            
            geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in 
                if let placemark = place where error == nil && placemark.count > 0 {
                    self.currentAddress = placemark[0]
                    self.titleViewButton.setTitle("Near \(placemark[0].cityStateString())", forState: .Normal)
                    self.titleViewButton.sizeToFit()
                }
                else {
                    self.title = lastLocation.coordinate.formatedString()
                }
                
                if self.refreshControl.superview == nil {
                    self.tableView.addSubview(self.refreshControl)
                }
                self.handleRefresh()
            }
            
            currentLocation = lastLocation
            manager.stopUpdatingLocation()
            manager.delegate = nil
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        manager.stopUpdatingLocation()
        manager.delegate = nil
    }
    
}

extension RecentViewController: NSFetchedResultsControllerDelegate
{
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? QuakeCell {
                if let quake = fetchedResultsController.objectAtIndexPath(indexPath!) as? Quake {
                    cell.configure(quake)
                }
            }
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        tableView.endUpdates()
    }
    
}

extension RecentViewController: UITableViewDataSource, UITableViewDelegate
{
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return QuakeCell.cellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(QuakeCell.reuseIdentifier) as? QuakeCell else {
            fatalError("Expected to dequeue a 'QuakeCell'.")
        }
        
        if let quake = fetchedResultsController.objectAtIndexPath(indexPath) as? Quake {
            cell.configure(quake)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//        searchController.searchBar.resignFirstResponder()
//        
//        if filteredLocations != nil {
//            let detailVC = LocationDetailViewController()
//            detailVC.locationToDisplay = filteredLocations![indexPath.row]
//            navigationController?.pushViewController(detailVC, animated: true)
//        }
//        else if let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Location {
//            let detailVC = LocationDetailViewController()
//            detailVC.locationToDisplay = location
//            navigationController?.pushViewController(detailVC, animated: true)
//        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
    }
    
}
