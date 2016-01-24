
import UIKit
import CoreData
import CoreLocation


class QuakesViewController: UITableViewController
{
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.moc
        
        let fetchRequest = Quake.fetchRequest(moc, predicate: nil, sortedBy: "timestamp", ascending: false)
        fetchRequest.fetchBatchSize = 20
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "quakes")
    }()
    
    lazy var titleViewButton: UIButton = {
        let button = UIButton(type: .Custom)
        
        button.backgroundColor = StyleController.darkerMainAppColor
        button.titleLabel?.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.addTarget(self, action: "titleButtonPressed", forControlEvents: .TouchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 4.0
        button.sizeToFit()
        
        return button
    }()
    
    private let locationManager = CLLocationManager()
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let geocoder = CLGeocoder()
    private var transitionAnimator: TextBarAnimator?

    var currentLocation: CLLocation?

    deinit {
        fetchedResultsController.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = titleViewButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "world-bar-icon"),
            landscapeImagePhone: nil,
            style: .Plain,
            target: self,
            action: "mapButtonPressed"
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "settings-bar-icon"),
            style: .Plain,
            target: self,
            action: "settingsButtonPressed"
        )
        navigationItem.rightBarButtonItem?.enabled = false
        
        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.estimatedRowHeight = QuakeCell.cellHeight
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.registerNib(UINib(nibName: QuakeCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: QuakeCell.reuseIdentifier)
        
        let refresher = UIRefreshControl()
        refresher.tintColor = StyleController.contrastColor
        refresher.backgroundColor = StyleController.backgroundColor
        refresher.addTarget(self, action: "fetchQuakes", forControlEvents: .ValueChanged)
        refreshControl = refresher
                
        preformFetch()
        fetchQuakes()
    }
    
    private func preformFetch() {
        if fetchedResultsController.delegate == nil {
            fetchedResultsController.delegate = self
        }
        
        do {
            try fetchedResultsController.performFetch()
            if navigationItem.rightBarButtonItem?.enabled == false {
                navigationItem.rightBarButtonItem?.enabled = true
            }
        }
            
        catch {
            print("Error fetching for the results controller: \(error)")
            navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    private func setTitleButtonText(textToSet: String) {
        titleViewButton.setTitle(textToSet, forState: .Normal)
        titleViewButton.sizeToFit()
    }
    
    private func presentFinder() {
        titleViewButton.hidden = true
        transitionAnimator = TextBarAnimator(duration: 0.345, presentingViewController: true, originatingFrame: titleViewButton.frame, completion: {
            self.titleViewButton.hidden = false
        })
        
        let finderVC = LocationFinderViewController()
        finderVC.delegate = self
        finderVC.transitioningDelegate = self
        presentViewController(finderVC, animated: true, completion: nil)
    }
    
    private func commonFetchedQuakes(quakes: [ParsedQuake]) {
        PersistentController.sharedController.saveQuakes(quakes)
        
        if let refresher = self.refreshControl where refresher.refreshing {
            refresher.endRefreshing()
        }
    }
    
    // MARK: - Actions
    func mapButtonPressed() {
        navigationController?.pushViewController(MapViewController(), animated: true)
    }
    
    func titleButtonPressed() {
        presentFinder()
    }
    
    func settingsButtonPressed() {
        // present settings vc
    }
    
    func fetchQuakes() {
        if SettingsController.sharedContoller.fisrtLaunchDate == nil {
            SettingsController.sharedContoller.lastLocationOption = LocationOption.World.rawValue
        }
        
        if let lastPlace = SettingsController.sharedContoller.lastSearchedPlace {
            setTitleButtonText("\(lastPlace.cityStateString())")

            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            NetworkClient.sharedClient.getRecentQuakesByLocation(lastPlace.location!.coordinate, radius: SettingsController.sharedContoller.searchRadius) { quakes, error in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                if let quakes = quakes where error == nil {
                    self.commonFetchedQuakes(quakes)
                }
            }
            return
        }
        
        if let option = SettingsController.sharedContoller.lastLocationOption {
            switch option {
            case LocationOption.Nearby.rawValue:
                if let current = currentLocation {
                    setTitleButtonText("\(SettingsController.sharedContoller.cachedAddress!.cityStateString())")
                    
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    NetworkClient.sharedClient.getRecentQuakesByLocation(current.coordinate, radius: SettingsController.sharedContoller.searchRadius) { quakes, error in
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        if let quakes = quakes where error == nil {
                            self.commonFetchedQuakes(quakes)
                        }
                    }
                }
                else {
                    setTitleButtonText("Locating...")
                    
                    switch CLLocationManager.authorizationStatus() {
                    case .AuthorizedWhenInUse:
                        if CLLocationManager.locationServicesEnabled() {
                            startLocationManager()
                        }
                    case .NotDetermined:
                        locationManager.delegate = self
                        locationManager.requestWhenInUseAuthorization()
                    default:
                        SettingsController.sharedContoller.lastLocationOption = nil
                        presentFinder()
                        break
                    }
                }
                break
            case LocationOption.World.rawValue:
                setTitleButtonText("Worldwide Earthquakes")
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                NetworkClient.sharedClient.getRecentWorldQuakes(shouldLimit: true) { quakes, error in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if let quakes = quakes where error == nil {
                        self.commonFetchedQuakes(quakes)
                    }
                }
                break
            case LocationOption.Major.rawValue:
                setTitleButtonText("Major Earthquakes")
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                NetworkClient.sharedClient.getRecentMajorQuakes { quakes, error in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if let quakes = quakes where error == nil {
                        self.commonFetchedQuakes(quakes)
                    }
                }
                break
            default:
                print("WARNING: Invalid option stored in 'SettingsController'.")
                break
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return QuakeCell.cellHeight
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(QuakeCell.reuseIdentifier) as? QuakeCell else {
            fatalError("Expected to dequeue a 'QuakeCell'.")
        }
        
        if let quake = fetchedResultsController.objectAtIndexPath(indexPath) as? Quake {
            cell.configure(quake)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let quake = fetchedResultsController.objectAtIndexPath(indexPath) as? Quake {
            let detailVC = DetailViewController(quake: quake)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
    }
    
}

extension QuakesViewController: CLLocationManagerDelegate
{
    // MARK: - Location Manager Delegate
    func startLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestLocation()
    }
    
    func stopLocationManager() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            startLocationManager()
        }
        else if status == .Denied {
            stopLocationManager()
            SettingsController.sharedContoller.lastLocationOption = nil
            presentFinder()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            currentLocation = lastLocation
            stopLocationManager()
            
            if let cachedAddress = SettingsController.sharedContoller.cachedAddress,
                let cachedLocation = cachedAddress.location where lastLocation.distanceFromLocation(cachedLocation) > 2500 {
                    geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] places, error in
                        if let placemark = places?.first where error == nil {
                            SettingsController.sharedContoller.cachedAddress = placemark
                            self.setTitleButtonText("\(placemark.cityStateString())")
                        }
                        else {
                            self.title = lastLocation.coordinate.formatedString()
                        }
                        
                        self.fetchQuakes()
                    }
            }
            else {
                if let cachedAddress = SettingsController.sharedContoller.cachedAddress {
                    titleViewButton.setTitle("\(cachedAddress.cityStateString())", forState: .Normal)
                    titleViewButton.sizeToFit()
                    fetchQuakes()
                }
                else {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
                        if let placemark = place?.first where error == nil {
                            SettingsController.sharedContoller.cachedAddress = placemark
                            self.setTitleButtonText("\(placemark.cityStateString())")
                        }
                        else {
                            self.title = lastLocation.coordinate.formatedString()
                        }
                        
                        self.fetchQuakes()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        stopLocationManager()
    }
    
}

extension QuakesViewController: NSFetchedResultsControllerDelegate
{
    
    // MARK: - NSFetchedResultsController Delegate
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

extension QuakesViewController: LocationFinderViewControllerDelegate
{
    
    // MARK: - LocationSelectionViewController Delegate
    func locationFinderViewControllerDidSelectPlace(placemark: CLPlacemark) {
        dismissViewControllerAnimated(true, completion: nil)
        
        SettingsController.sharedContoller.lastSearchedPlace = placemark
        SettingsController.sharedContoller.lastLocationOption = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
    func locationFinderViewControllerDidSelectOption(option: LocationOption) {
        dismissViewControllerAnimated(true, completion: nil)
        
        SettingsController.sharedContoller.lastLocationOption = option.rawValue
        SettingsController.sharedContoller.lastSearchedPlace = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
}

extension QuakesViewController: UIViewControllerTransitioningDelegate
{
    // MARK: - UIViewControllerTransitioning Delegate
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionAnimator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator?.presenting = false
        return transitionAnimator
    }
}
