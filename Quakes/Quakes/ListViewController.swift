
import UIKit
import CoreData
import CoreLocation
import GoogleMobileAds

class ListViewController: UIViewController
{
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var bannerViewBottomConstraint: NSLayoutConstraint!
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = PersistentController.sharedController.moc
        
        let fetchRequest = Quake.fetchRequest(moc, predicate: nil, sortedBy: "timestamp", ascending: false)
        fetchRequest.fetchBatchSize = 75
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "quakes")
    }()
    
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Recent Quakes"
        label.font = UIFont.systemFontOfSize(22.0, weight: UIFontWeightMedium)
        label.textColor = UIColor(white: 0.0, alpha: 0.25)
        label.sizeToFit()
        return label
    }()
    
    lazy var titleViewButton: UIButton = {
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
    
    lazy var lastFetchDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .ShortStyle
        
        return formatter
    }()
    
    private lazy var refresher = UIRefreshControl()
    private lazy var locationManager = CLLocationManager()
    private lazy var defaults = NSUserDefaults.standardUserDefaults()
    private lazy var geocoder = CLGeocoder()
    private var transitionAnimator: TextBarAnimator?

    var currentLocation: CLLocation? = SettingsController.sharedController.cachedAddress?.location

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
            action: #selector(ListViewController.mapButtonPressed)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "settings-gear"),
            style: .Plain,
            target: self,
            action: #selector(ListViewController.settingsButtonPressed)
        )
        navigationItem.rightBarButtonItem?.enabled = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = QuakeCell.cellHeight
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.registerNib(UINib(nibName: QuakeCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: QuakeCell.reuseIdentifier)
        
        refresher.tintColor = StyleController.contrastColor
        refresher.backgroundColor = StyleController.backgroundColor
        refresher.attributedTitle = NSAttributedString(string: "Last updated: \(lastFetchDateFormatter.stringFromDate(SettingsController.sharedController.lastFetchDate))")
        refresher.addTarget(self, action: #selector(ListViewController.fetchQuakes), forControlEvents: .ValueChanged)
        tableView.addSubview(refresher)
        
        bannerView.adUnitID = "ca-app-pub-6493864895252732/6300764804"
        bannerView.delegate = self
        bannerView.rootViewController = self
        bannerView.backgroundColor = StyleController.backgroundColor
        
        if !SettingsController.sharedController.hasSupported {
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            
            bannerView.loadRequest(request)
        }
        
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
        
        preformFetch()
        fetchQuakes()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
        transitionAnimator = TextBarAnimator(duration: 0.3, presentingViewController: true, originatingFrame: titleViewButton.frame, completion: {
            self.titleViewButton.hidden = false
        })
        
        let finderVC = LocationFinderViewController()
        finderVC.delegate = self
        finderVC.transitioningDelegate = self
        presentViewController(finderVC, animated: true, completion: nil)
    }
    
    private func commonFinishedFetch() {
        if fetchedResultsController.fetchedObjects?.count == 0 && tableView.numberOfRowsInSection(0) == 0 {
            noResultsLabel.center = CGPoint(x: view.center.x, y: 115.0)
            tableView.addSubview(noResultsLabel)
        }
        else {
            navigationItem.rightBarButtonItem?.enabled = true
        }
        
        if refresher.refreshing {
            refresher.endRefreshing()
        }
    }
    
    // MARK: - Notifications
    func applicationDidEnterForeground() {
        tableView.reloadData()
    }
    
    func settingsDidPurchaseAdRemoval() {
        if bannerViewBottomConstraint.constant == 0 {
            UIView.animateWithDuration(0.3) {
                self.bannerViewBottomConstraint.constant = -self.bannerView.frame.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func settingsDidChangeUnitStyle() {
        tableView.reloadData()
    }
    
    func settingsDidUpdateLastFetchDate() {
        let attrString = NSAttributedString(string: "Last updated: \(lastFetchDateFormatter.stringFromDate(SettingsController.sharedController.lastFetchDate))")
        refresher.attributedTitle = attrString
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
            if refresher.refreshing {
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
                if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                self.commonFinishedFetch()
            }
            return
        }
        
        if let option = SettingsController.sharedController.lastLocationOption {
            switch option {
            case LocationOption.Nearby.rawValue:
                if let current = currentLocation {
                    setTitleButtonText("\(SettingsController.sharedController.cachedAddress!.cityStateString())")
                    
                    NetworkClient.sharedClient.getQuakesByLocation(current.coordinate) { quakes, error in
                        if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                        self.commonFinishedFetch()
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
                    if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                    self.commonFinishedFetch()
                }
                break
            case LocationOption.Major.rawValue:
                setTitleButtonText("Major Quakes")
                
                NetworkClient.sharedClient.getMajorQuakes { quakes, error in
                    if let recievedQuakes = quakes { PersistentController.sharedController.saveQuakes(recievedQuakes) }
                    self.commonFinishedFetch()
                }
                break
            default:
                print("WARNING: Invalid option stored in 'SettingsController'.")
                break
            }
        }
    }
    
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource
{
    
    // MARK: - UITableView Delegate
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
        
        if let quake = fetchedResultsController.objectAtIndexPath(indexPath) as? Quake {
            navigationController?.pushViewController(DetailViewController(quake: quake), animated: true)
        }
    }
    
    // MARK: - UITableView DataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let section = fetchedResultsController.sections?[section]
        
        return section?.numberOfObjects ?? 0
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

extension ListViewController: NotificationPromptViewControllerDelegate
{
    
    // MARK: NotificationPromptViewController Delegate
    func notificationPromptViewControllerDidAllowNotifications() {
        dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().registerUserNotificationSettings(
                UIUserNotificationSettings(forTypes: .Alert, categories: nil)
            )
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

extension ListViewController: GADBannerViewDelegate
{
    
    // MARK: - GADBannerView Delegate
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        if bannerViewBottomConstraint.constant == 0 {
            UIView.animateWithDuration(0.23) {
                self.bannerViewBottomConstraint.constant = -bannerView.frame.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        if bannerViewBottomConstraint.constant != 0 && !SettingsController.sharedController.hasSupported {
            UIView.animateWithDuration(0.23) {
                self.bannerViewBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
}
