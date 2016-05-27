
import UIKit
import CoreData
import CoreLocation

class ListViewController: UITableViewController
{
    
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Recent Quakes"
        label.font = UIFont.systemFontOfSize(22.0, weight: UIFontWeightMedium)
        label.textColor = UIColor(white: 0.0, alpha: 0.25)
        label.sizeToFit()
        return label
    }()
    
    private lazy var titleViewButton: UIButton = {
        let button = UIButton(type: .Custom)
        
        button.backgroundColor = StyleController.searchBarColor
        button.titleLabel?.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.addTarget(self, action: #selector(ListViewController.titleButtonPressed), forControlEvents: .TouchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 4.0
        button.sizeToFit()
        
        return button
    }()
    
    private lazy var locationManager = CLLocationManager()
    private lazy var defaults = NSUserDefaults.standardUserDefaults()
    private lazy var geocoder = CLGeocoder()
    private var transitionAnimator: TextBarAnimator?
    private var fetchedResultsController: NSFetchedResultsController?

    private var currentLocation: CLLocation? = SettingsController.sharedController.cachedAddress?.location

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Quakes"
        
        navigationItem.titleView = titleViewButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "world-bar-icon"),
            landscapeImagePhone: nil,
            style: .Plain,
            target: self,
            action: #selector(ListViewController.mapButtonPressed)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "settings-gear"),
            style: .Plain,
            target: self,
            action: #selector(ListViewController.settingsButtonPressed)
        )
        navigationItem.rightBarButtonItem?.enabled = false
        
        tableView.estimatedRowHeight = QuakeCell.cellHeight
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.registerNib(UINib(nibName: QuakeCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: QuakeCell.reuseIdentifier)
        tableView.registerNib(UINib(nibName: NativeAdCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: NativeAdCell.reuseIdentifier)
        
        refreshControl = {
            let refresher = UIRefreshControl()
            
            refresher.tintColor = StyleController.contrastColor
            refresher.backgroundColor = StyleController.backgroundColor
            refresher.addTarget(self, action: #selector(ListViewController.fetchQuakes), forControlEvents: .ValueChanged)
            
            return refresher
        }()
        
        fetchedResultsController = {
            let moc = PersistentController.sharedController.moc
            
            let fetchRequest = Quake.fetchRequest(moc, predicate: nil, sortedBy: "timestamp", ascending: false)
            fetchRequest.fetchBatchSize = 20
            
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "quakes")
        }()
        fetchedResultsController?.delegate = self
        
        beginObserving()
        preformFetch()
        fetchQuakes()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func preformFetch() {
        do {
            try fetchedResultsController?.performFetch()
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
        transitionAnimator = TextBarAnimator(duration: 0.3, presentingViewController: true, originatingFrame: titleViewButton.frame) {
            self.titleViewButton.hidden = false
        }
        
        let finderVC = LocationFinderViewController()
        finderVC.delegate = self
        finderVC.transitioningDelegate = self
        presentViewController(finderVC, animated: true, completion: nil)
    }
    
    private func commonFinishedFetch(quakes: [ParsedQuake]?) {
        if let recievedQuakes = quakes where recievedQuakes.count > 0 {
            PersistentController.sharedController.saveQuakes(recievedQuakes)
        }
        
        if fetchedResultsController?.sections?.count > 0 {
            if noResultsLabel.superview != nil {
                noResultsLabel.removeFromSuperview()
            }
            
            navigationItem.rightBarButtonItem?.enabled = true
        }
        else {
            noResultsLabel.center = CGPoint(x: view.center.x, y: 115.0)
            tableView.addSubview(noResultsLabel)
            
            navigationItem.rightBarButtonItem?.enabled = false
        }
        
        if let refresher = refreshControl where refresher.refreshing {
            refresher.endRefreshing()
        }
    }
    
    private func shouldLoadAdAtIndexPath(indexPath: NSIndexPath) -> Bool {
        guard SettingsController.sharedController.hasSupported else { return false }
        return indexPath.row == 3 || indexPath.row % 34 == 3
    }
    
    private func beginObserving() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ListViewController.settingsDidChangeUnitStyle),
            name: SettingsController.kSettingsControllerDidChangeUnitStyleNotification,
            object: nil
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ListViewController.settingsDidPurchaseAdRemoval),
            name: SettingsController.kSettingsControllerDidChangePurchaseAdRemovalNotification,
            object: nil
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ListViewController.applicationDidEnterForeground),
            name: UIApplicationDidBecomeActiveNotification,
            object: nil
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ListViewController.settingsDidUpdateLastFetchDate),
            name: SettingsController.kSettingsControllerDidUpdateLastFetchDateNotification,
            object: nil
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ListViewController.settingsDidUpdateLocationForPush),
            name: SettingsController.kSettingsControllerDidUpdateLocationForPushNotification,
            object: nil
        )
    }
    
    // MARK: - UITableView Delegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if shouldLoadAdAtIndexPath(indexPath) {
            return NativeAdCell.cellHeight
        }
        else {
            return QuakeCell.cellHeight
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if shouldLoadAdAtIndexPath(indexPath) {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(NativeAdCell.reuseIdentifier) as? NativeAdCell else {
                fatalError("Expected to dequeue a 'NativeAdCell'.")
            }
            
            cell.nativeExpressAdView.rootViewController = self
            cell.loadRequest()
            
            return cell
        }
        else {
            guard let cell = tableView.dequeueReusableCellWithIdentifier(QuakeCell.reuseIdentifier) as? QuakeCell else {
                fatalError("Expected to dequeue a 'QuakeCell'.")
            }
            
            if let quake = fetchedResultsController?.objectAtIndexPath(indexPath) as? Quake {
                cell.configure(quake)
            }
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let quake = fetchedResultsController?.objectAtIndexPath(indexPath) as? Quake {
            navigationController?.pushViewController(DetailViewController(quake: quake), animated: true)
        }
    }
    
    // MARK: - UITableView DataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController?.sections?[section] else { return 0 }
        
        let objectCount = section.numberOfObjects
        
        var tableAds = 0
        for idx in 0..<objectCount where SettingsController.sharedController.hasSupported {
            if idx == 3 {
                tableAds += 1
            }
            else if idx % 34 == 3 {
                tableAds += 1
            }
        }
        
        return objectCount + tableAds
    }
    
    // MARK: - Notifications
    func applicationDidEnterForeground() {
        tableView.reloadData()
    }
    
    func settingsDidPurchaseAdRemoval() {
        tableView.reloadData()
    }
    
    func settingsDidChangeUnitStyle() {
        tableView.reloadData()
    }
    
    func settingsDidUpdateLastFetchDate() {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        
        let lastFetchDate = SettingsController.sharedController.lastFetchDate
        var attrString = ""
        
        if lastFetchDate.isToday() {
            formatter.dateStyle = .NoStyle
            attrString = "Last updated: Today at \(formatter.stringFromDate(lastFetchDate))"
        }
        else {
            formatter.dateStyle = .ShortStyle
            attrString = "Last updated: \(formatter.stringFromDate(lastFetchDate))"
        }
        
        refreshControl?.attributedTitle = NSAttributedString(string: attrString)
    }
    
    func settingsDidUpdateLocationForPush() {
        guard let token = SettingsController.sharedController.pushToken else { return }
        guard let location = SettingsController.sharedController.locationEligableForNotifications() else { return }
        NetworkClient.sharedClient.registerForNotificationsWithToken(token, location: location)
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
        navigationItem.rightBarButtonItem?.enabled = false
        
        guard NetworkUtility.internetReachable() else {
            if let refresher = refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
            return
        }
        
        if noResultsLabel.superview != nil {
            noResultsLabel.removeFromSuperview()
        }
        
        if SettingsController.sharedController.lastLocationOption == nil && SettingsController.sharedController.lastSearchedPlace == nil {
            presentFinder()
            return
        }
        
        if let lastPlace = SettingsController.sharedController.lastSearchedPlace {
            setTitleButtonText("\(lastPlace.cityStateString())")

            NetworkClient.sharedClient.getQuakesByLocation(lastPlace.location!.coordinate) { quakes, error in
                self.commonFinishedFetch(quakes)
            }
            return
        }
        
        if let option = SettingsController.sharedController.lastLocationOption {
            switch option {
            case LocationOption.Nearby.rawValue:
                if let current = currentLocation {
                    setTitleButtonText("\(SettingsController.sharedController.cachedAddress!.cityStateString())")
                    
                    NetworkClient.sharedClient.getQuakesByLocation(current.coordinate) { quakes, error in
                        self.commonFinishedFetch(quakes)
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
                
                NetworkClient.sharedClient.getWorldQuakes() { quakes, error in
                    self.commonFinishedFetch(quakes)
                }
                break
            case LocationOption.Major.rawValue:
                setTitleButtonText("Major Quakes")
                
                NetworkClient.sharedClient.getMajorQuakes() { quakes, error in
                    self.commonFinishedFetch(quakes)
                }
                break
            default:
                print("WARNING: Invalid option stored in 'SettingsController'.")
                break
            }
        }
    }
    
}

extension ListViewController: CLLocationManagerDelegate
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
        guard let lastLocation = locations.last else {
            return
        }
        
        currentLocation = lastLocation
        stopLocationManager()
        
        if let cachedAddress = SettingsController.sharedController.cachedAddress {
            if let cachedLocation = cachedAddress.location where lastLocation.distanceFromLocation(cachedLocation) > 5 * 1000 {
                geocoder.reverseGeocodeLocation(lastLocation) { [weak self] places, error in
                    if let placemark = places?.first where error == nil {
                        SettingsController.sharedController.cachedAddress = placemark
                        self?.setTitleButtonText("\(placemark.cityStateString())")
                    }
                    else {
                        self?.setTitleButtonText("Location Error")
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                            self?.presentFinder()
                        }
                    }
                    
                    self?.fetchQuakes()
                }
            }
            else {
                setTitleButtonText(cachedAddress.cityStateString())
                fetchQuakes()
            }
        }
        else {
            NetworkUtility.networkOperationStarted()
            geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
                NetworkUtility.networkOperationFinished()
                
                if let placemark = place?.first where error == nil {
                    SettingsController.sharedController.cachedAddress = placemark
                    self.setTitleButtonText("\(placemark.cityStateString())")
                }
                else {
                    self.setTitleButtonText("Location Error")
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.presentFinder()
                    }
                }
                
                self.fetchQuakes()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        if let cachedAddress = SettingsController.sharedController.cachedAddress {
            setTitleButtonText(cachedAddress.cityStateString())
        }
        else {
            setTitleButtonText("Location Error")
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                self.presentFinder()
            }
        }
        
        stopLocationManager()
    }
    
}

extension ListViewController: NSFetchedResultsControllerDelegate
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
            if let newIndexPathToInsert = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPathToInsert], withRowAnimation: .Automatic)
            }
            
        case .Delete:
            if let oldIndexPathToDelete = indexPath {
                tableView.deleteRowsAtIndexPaths([oldIndexPathToDelete], withRowAnimation: .Automatic)
            }
            
        case .Update:
            if let indexPath = indexPath, let cell = tableView.cellForRowAtIndexPath(indexPath) as? QuakeCell {
                if let quake = fetchedResultsController?.objectAtIndexPath(indexPath) as? Quake {
                    cell.configure(quake)
                }
            }
            
        case .Move:
            if let newIndexPathToInsert = newIndexPath, let oldIndexPathToDelete = indexPath {
                tableView.deleteRowsAtIndexPaths([oldIndexPathToDelete], withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths([newIndexPathToInsert], withRowAnimation: .Automatic)
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        tableView.endUpdates()
    }
    
}

extension ListViewController: LocationFinderViewControllerDelegate
{
    
    // MARK: - LocationFinderViewController Delegate
    func locationFinderViewControllerDidSelectPlace(placemark: CLPlacemark) {
        dismissViewControllerAnimated(true, completion: nil)
        
        TelemetryController.sharedController.logQuakeFinderDidSelectLocation(placemark.cityStateString())
        
        SettingsController.sharedController.lastSearchedPlace = placemark
        SettingsController.sharedController.lastLocationOption = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
    func locationFinderViewControllerDidSelectOption(option: LocationOption) {
        dismissViewControllerAnimated(true, completion: nil)
        
        TelemetryController.sharedController.logQuakeFinderDidSelectLocation(option.rawValue)
        
        SettingsController.sharedController.lastLocationOption = option.rawValue
        SettingsController.sharedController.lastSearchedPlace = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
}

extension ListViewController: MapViewControllerDelegate
{
    
    // MARK: - MapViewController Delegate
    func mapViewControllerDidFinishFetch(sucess: Bool, withPlace placemark: CLPlacemark) {
        if sucess {
            setTitleButtonText("\(placemark.cityStateString())")
        }
        
        if !sucess && fetchedResultsController?.fetchedObjects?.count == 0 && tableView.numberOfRowsInSection(0) == 0 {
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

extension ListViewController: UIViewControllerTransitioningDelegate
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
