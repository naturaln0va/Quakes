
import UIKit
import CoreData
import CoreLocation


class RecentViewController: UIViewController
{
    
    private static let cachedPlacemarkKey = "cachedPlace"
    
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
    var currentLocation: CLLocation? {
        didSet {
            refreshControl.enabled = currentLocation != nil
        }
    }
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var cachedAddress: CLPlacemark? {
        get {
            if let data = defaults.objectForKey(RecentViewController.cachedPlacemarkKey) as? NSData,
                let place = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CLPlacemark {
                return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(newPlace), forKey: RecentViewController.cachedPlacemarkKey)
            }
        }
    }

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
        
        refreshControl.enabled = false
        refreshControl.tintColor = StyleController.contrastColor
        refreshControl.backgroundColor = StyleController.mainAppColor
        refreshControl.addTarget(self, action: "fetchQuakes", forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        
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
    
    func fetchQuakes()
    {
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
            if let cachedAddress = cachedAddress, let cachedLocation = cachedAddress.location where lastLocation.distanceFromLocation(cachedLocation) > 2500 {
                geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
                    if let placemark = place where error == nil && placemark.count > 0 {
                        self.cachedAddress = placemark[0]
                        self.titleViewButton.setTitle("Near \(placemark[0].cityStateString())", forState: .Normal)
                        self.titleViewButton.sizeToFit()
                    }
                    else {
                        self.title = lastLocation.coordinate.formatedString()
                    }
                    
                    self.fetchQuakes()
                }
            }
            else {
                if let cachedAddress = cachedAddress {
                    titleViewButton.setTitle("Near \(cachedAddress.cityStateString())", forState: .Normal)
                    titleViewButton.sizeToFit()
                    fetchQuakes()
                }
                else {
                    geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
                        if let placemark = place?.first where error == nil {
                            self.cachedAddress = placemark
                            self.titleViewButton.setTitle("Near \(placemark.cityStateString())", forState: .Normal)
                            self.titleViewButton.sizeToFit()
                        }
                        else {
                            self.title = lastLocation.coordinate.formatedString()
                        }
                        
                        self.fetchQuakes()
                    }

                }
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
        
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
    }
    
}
