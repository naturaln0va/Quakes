
import UIKit
import CoreData
import CoreLocation
import iAd


class QuakesViewController: UITableViewController
{
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.moc
        
        let fetchRequest = Quake.fetchRequest(moc, predicate: nil, sortedBy: "timestamp", ascending: false)
        fetchRequest.fetchBatchSize = 20
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "quakes")
    }()
    
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Recent Quakes"
        label.font = UIFont.systemFontOfSize(27.0, weight: UIFontWeightMedium)
        label.textColor = UIColor(white: 0.0, alpha: 0.25)
        label.sizeToFit()
        return label
    }()
    
    lazy var titleViewButton: UIButton = {
        let button = UIButton(type: .Custom)
        
        button.backgroundColor = StyleController.searchBarColor
        button.titleLabel?.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
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
        
        title = "Quakes"
        
        navigationItem.titleView = titleViewButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "world-bar-icon"),
            landscapeImagePhone: nil,
            style: .Plain,
            target: self,
            action: "mapButtonPressed"
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "settings-gear"),
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
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "settingsDidChangeUnitStyle",
            name: SettingsController.kSettingsControllerDidChangeUnitStyleNotification,
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "settingsDidPurchaseAdRemoval",
            name: SettingsController.kSettingsControllerDidChangePurchaseAdRemovalNotification,
            object: nil
        )
        
        preformFetch()
        fetchQuakes()
        
        canDisplayBannerAds = !SettingsController.sharedController.hasPaidToRemoveAds
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NetworkClient.sharedClient.cancelAllCurrentRequests()
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
        
        let finderVC = LocationFinderViewController(type: .Fetch)
        finderVC.delegate = self
        finderVC.transitioningDelegate = self
        presentViewController(finderVC, animated: true, completion: nil)
    }
    
    private func commonFetchedQuakes(quakes: [ParsedQuake]) {
        if quakes.count == 0 && fetchedResultsController.fetchedObjects?.count == 0 && tableView.numberOfRowsInSection(0) == 0 {
            noResultsLabel.center = CGPoint(x: view.center.x, y: 65.0)
            tableView.addSubview(noResultsLabel)
        }
        
        PersistentController.sharedController.saveQuakes(quakes)
        
        if let refresher = refreshControl where refresher.refreshing {
            refresher.endRefreshing()
        }
    }
    
    // MARK: - Notifications
    func settingsDidPurchaseAdRemoval() {
        canDisplayBannerAds = !SettingsController.sharedController.hasPaidToRemoveAds
    }
    
    func settingsDidChangeUnitStyle() {
        tableView.reloadData()
    }
    
    // MARK: - Actions
    func mapButtonPressed() {
        guard NetworkUtility.internetReachable() else {
            return
        }
        let mapVC = MapViewController(quakeToDisplay: nil, nearbyCities: nil)
        mapVC.delegate = self
        navigationController?.pushViewController(mapVC, animated: true)
    }
    
    func titleButtonPressed() {
        guard NetworkUtility.internetReachable() else { return }
        presentFinder()
    }
    
    func settingsButtonPressed() {
        presentViewController(StyledNavigationController(rootViewController: SettingsViewController()), animated: true, completion: nil)
    }
    
    func fetchQuakes() {
        guard NetworkUtility.internetReachable() else {
            if let refresher = refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
            return
        }
        
        if noResultsLabel.superview != nil {
            noResultsLabel.removeFromSuperview()
        }
        
        if SettingsController.sharedController.fisrtLaunchDate == nil {
            SettingsController.sharedController.lastLocationOption = LocationOption.World.rawValue
        }
        
        if let lastPlace = SettingsController.sharedController.lastSearchedPlace {
            setTitleButtonText("\(lastPlace.cityStateString())")

            NetworkUtility.networkOperationStarted()
            NetworkClient.sharedClient.getRecentQuakesByLocation(lastPlace.location!.coordinate) { quakes, error in
                NetworkUtility.networkOperationFinished()

                if let quakes = quakes where error == nil {
                    self.commonFetchedQuakes(quakes)
                }
            }
            return
        }
        
        if let option = SettingsController.sharedController.lastLocationOption {
            switch option {
            case LocationOption.Nearby.rawValue:
                if let current = currentLocation {
                    setTitleButtonText("\(SettingsController.sharedController.cachedAddress!.cityStateString())")
                    
                    NetworkUtility.networkOperationStarted()
                    NetworkClient.sharedClient.getRecentQuakesByLocation(current.coordinate) { quakes, error in
                        NetworkUtility.networkOperationFinished()
                        
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
                        SettingsController.sharedController.lastLocationOption = nil
                        presentFinder()
                        break
                    }
                }
                break
            case LocationOption.World.rawValue:
                setTitleButtonText("Worldwide Quakes")
                
                NetworkUtility.networkOperationStarted()
                NetworkClient.sharedClient.getRecentWorldQuakes() { quakes, error in
                    NetworkUtility.networkOperationFinished()
                    
                    if let quakes = quakes where error == nil {
                        self.commonFetchedQuakes(quakes)
                    }
                }
                break
            case LocationOption.Major.rawValue:
                setTitleButtonText("Major Quakes")
                
                NetworkUtility.networkOperationStarted()
                NetworkClient.sharedClient.getRecentMajorQuakes { quakes, error in
                    NetworkUtility.networkOperationFinished()
                    
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
            navigationController?.pushViewController(QuakeDetailViewController(quake: quake), animated: true)
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
            SettingsController.sharedController.lastLocationOption = nil
            presentFinder()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            currentLocation = lastLocation
            stopLocationManager()
            
            if let cachedAddress = SettingsController.sharedController.cachedAddress,
                let cachedLocation = cachedAddress.location where lastLocation.distanceFromLocation(cachedLocation) > 2500 {
                    geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] places, error in
                        if let placemark = places?.first where error == nil {
                            SettingsController.sharedController.cachedAddress = placemark
                            self.setTitleButtonText("\(placemark.cityStateString())")
                        }
                        else {
                            self.title = lastLocation.coordinate.formatedString()
                        }
                        
                        self.fetchQuakes()
                    }
            }
            else {
                if let cachedAddress = SettingsController.sharedController.cachedAddress {
                    titleViewButton.setTitle("\(cachedAddress.cityStateString())", forState: .Normal)
                    titleViewButton.sizeToFit()
                    fetchQuakes()
                }
                else {
                    NetworkUtility.networkOperationStarted()
                    geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
                        if let placemark = place?.first where error == nil {
                            SettingsController.sharedController.cachedAddress = placemark
                            self.setTitleButtonText("\(placemark.cityStateString())")
                        }
                        else {
                            self.title = lastLocation.coordinate.formatedString()
                        }
                        
                        self.fetchQuakes()
                        NetworkUtility.networkOperationFinished()
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
        
        SettingsController.sharedController.lastSearchedPlace = placemark
        SettingsController.sharedController.lastLocationOption = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
    func locationFinderViewControllerDidSelectOption(option: LocationOption) {
        dismissViewControllerAnimated(true, completion: nil)
        
        SettingsController.sharedController.lastLocationOption = option.rawValue
        SettingsController.sharedController.lastSearchedPlace = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
}

extension QuakesViewController: MapViewControllerDelegate
{
    
    // MARK: - MapViewController Delegate
    func mapViewControllerDidFinishFetch(sucess: Bool, withPlace placemark: CLPlacemark) {
        if sucess {
            setTitleButtonText("\(placemark.cityStateString())")
            
            SettingsController.sharedController.lastSearchedPlace = placemark
            SettingsController.sharedController.lastLocationOption = nil
        }
        
        if !sucess && fetchedResultsController.fetchedObjects?.count == 0 && tableView.numberOfRowsInSection(0) == 0 {
            noResultsLabel.center = CGPoint(x: view.center.x, y: 65.0)
            tableView.addSubview(noResultsLabel)
        }
        else {
            if noResultsLabel.superview != nil {
                noResultsLabel.removeFromSuperview()
            }
        }
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

extension QuakesViewController: UIViewControllerPreviewingDelegate
{
    
    // MARK: - UIViewControllerPreviewing Delegate
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else {
            print("Unable to parse an indexPath for location: \(location)")
            return nil
        }
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        if let quake = fetchedResultsController.objectAtIndexPath(indexPath) as? Quake {
            previewingContext.sourceRect = cell.frame
            
            let peekVC = PeekableDetailViewController(quake: quake)
            peekVC.preferredContentSize = CGSize(width: 0.0, height: 300.0)
            
            return peekVC
        }
        
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is PeekableDetailViewController {
            navigationController?.pushViewController(QuakeDetailViewController(quake: (viewControllerToCommit as! PeekableDetailViewController).quakeToDisplay), animated: true)
        }
        else {
            print("the view controller to commit is a unsupported type: \(viewControllerToCommit.dynamicType)")
        }
    }
    
}
