
import UIKit
import CoreData
import CoreLocation
import GoogleMobileAds
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ListViewController: UITableViewController
{
    
    fileprivate lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Recent Quakes"
        label.font = UIFont.systemFont(ofSize: 22.0, weight: UIFontWeightMedium)
        label.textColor = UIColor(white: 0.0, alpha: 0.25)
        label.sizeToFit()
        return label
    }()
    
    fileprivate lazy var titleViewButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.backgroundColor = StyleController.searchBarColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightMedium)
        button.setTitleColor(UIColor.black, for: UIControlState())
        button.addTarget(self, action: #selector(ListViewController.titleButtonPressed), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 4.0
        button.sizeToFit()
        
        return button
    }()
    
    fileprivate lazy var locationManager = CLLocationManager()
    fileprivate lazy var defaults = UserDefaults.standard
    fileprivate lazy var geocoder = CLGeocoder()
    fileprivate var transitionAnimator: TextBarAnimator?
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    fileprivate var currentLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Quakes"
        
        navigationItem.titleView = titleViewButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "world-bar-icon"),
            landscapeImagePhone: nil,
            style: .plain,
            target: self,
            action: #selector(ListViewController.mapButtonPressed)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "settings-gear"),
            style: .plain,
            target: self,
            action: #selector(ListViewController.settingsButtonPressed)
        )
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        tableView.estimatedRowHeight = QuakeCell.cellHeight
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.register(UINib(nibName: QuakeCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: QuakeCell.reuseIdentifier)
        tableView.register(UINib(nibName: NativeAdCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: NativeAdCell.reuseIdentifier)
        
        refreshControl = {
            let refresher = UIRefreshControl()
            
            refresher.tintColor = StyleController.contrastColor
            refresher.backgroundColor = StyleController.backgroundColor
            refresher.addTarget(self, action: #selector(ListViewController.fetchQuakes), for: .valueChanged)
            
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    fileprivate func preformFetch() {
        do {
            try fetchedResultsController?.performFetch()
            if navigationItem.rightBarButtonItem?.isEnabled == false {
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
            
        catch {
            print("Error fetching for the results controller: \(error)")
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    fileprivate func setTitleButtonText(_ textToSet: String) {
        titleViewButton.setTitle(textToSet, for: UIControlState())
        titleViewButton.sizeToFit()
    }
    
    fileprivate func presentFinder() {
        titleViewButton.isHidden = true
        transitionAnimator = TextBarAnimator(duration: 0.3, presentingViewController: true, originatingFrame: titleViewButton.frame) {
            self.titleViewButton.isHidden = false
        }
        
        let finderVC = LocationFinderViewController()
        finderVC.delegate = self
        finderVC.transitioningDelegate = self
        present(finderVC, animated: true, completion: nil)
    }
    
    fileprivate func commonFinishedFetch(_ quakes: [ParsedQuake]?) {
        if let recievedQuakes = quakes, recievedQuakes.count > 0 {
            PersistentController.sharedController.saveQuakes(recievedQuakes)
        }
        
        if fetchedResultsController?.sections?.count > 0 {
            if noResultsLabel.superview != nil {
                noResultsLabel.removeFromSuperview()
            }
            
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else {
            noResultsLabel.center = CGPoint(x: view.center.x, y: 115.0)
            tableView.addSubview(noResultsLabel)
            
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        if let refresher = refreshControl, refresher.isRefreshing {
            refresher.endRefreshing()
        }
    }
    
    fileprivate func shouldLoadAdAtIndexPath(_ indexPath: IndexPath) -> Bool {
        guard !SettingsController.sharedController.hasSupported else { return false }
        return indexPath.section == 0
    }
    
    fileprivate func beginObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ListViewController.settingsDidChangeUnitStyle),
            name: NSNotification.Name(rawValue: SettingsController.kSettingsControllerDidChangeUnitStyleNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ListViewController.settingsDidPurchaseAdRemoval),
            name: NSNotification.Name(rawValue: SettingsController.kSettingsControllerDidChangePurchaseAdRemovalNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ListViewController.applicationDidEnterForeground),
            name: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ListViewController.settingsDidUpdateLocationForPush),
            name: NSNotification.Name(rawValue: SettingsController.kSettingsControllerDidUpdateLocationForPushNotification),
            object: nil
        )
    }
    
    // MARK: - UITableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if shouldLoadAdAtIndexPath(indexPath) {
            return NativeAdCell.cellHeight
        }
        else {
            return QuakeCell.cellHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldLoadAdAtIndexPath(indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NativeAdCell.reuseIdentifier) as? NativeAdCell else {
                fatalError("Expected to dequeue a 'NativeAdCell'.")
            }
            
            cell.nativeExpressAdView.rootViewController = self
            cell.loadRequest()
            
            return cell
        }
        else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: QuakeCell.reuseIdentifier) as? QuakeCell else {
                fatalError("Expected to dequeue a 'QuakeCell'.")
            }
            
            if let quake = fetchedResultsController?.fetchedObjects?[indexPath.row] as? Quake {
                cell.configure(quake)
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let quake = fetchedResultsController?.fetchedObjects?[indexPath.row] as? Quake {
            navigationController?.pushViewController(DetailViewController(quake: quake), animated: true)
        }
    }
    
    // MARK: - UITableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section > 0 else { return 1 }
        let objectCount = fetchedResultsController?.fetchedObjects?.count ?? 0
        return objectCount
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
        present(StyledNavigationController(rootViewController: SettingsViewController()), animated: true, completion: nil)
    }
    
    func fetchQuakes() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        guard NetworkUtility.internetReachable() else {
            if let refresher = refreshControl, refresher.isRefreshing {
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
                    case .authorizedWhenInUse:
                        if CLLocationManager.locationServicesEnabled() {
                            startLocationManager()
                        }
                    case .notDetermined:
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            startLocationManager()
        }
        else if status == .denied {
            stopLocationManager()
            SettingsController.sharedController.lastLocationOption = nil
            presentFinder()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }
        
        currentLocation = lastLocation
        stopLocationManager()
        
        NetworkUtility.networkOperationStarted()
        geocoder.reverseGeocodeLocation(lastLocation) { [unowned self] place, error in
            NetworkUtility.networkOperationFinished()
            
            if let placemark = place?.first, error == nil {
                SettingsController.sharedController.cachedAddress = placemark
                self.setTitleButtonText("\(placemark.cityStateString())")
            }
            else {
                self.setTitleButtonText("Location Error")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(2 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                    self.presentFinder()
                }
            }
            
            self.fetchQuakes()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        if error.code == CLError.Code.locationUnknown.rawValue {
//            return
//        }
        
        if let cachedAddress = SettingsController.sharedController.cachedAddress {
            setTitleButtonText(cachedAddress.cityStateString())
        }
        else {
            setTitleButtonText("Location Error")
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(2 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                self.presentFinder()
            }
        }
        
        stopLocationManager()
    }
    
}

extension ListViewController: NSFetchedResultsControllerDelegate
{
    
    // MARK: - NSFetchedResultsController Delegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard navigationController?.topViewController is ListViewController else { return }
        
        switch type {
        case .insert:
            if let newIndexPathToInsert = newIndexPath {
                let adjustedIndexPath = IndexPath(row: newIndexPathToInsert.row, section: 1)
                tableView.insertRows(at: [adjustedIndexPath], with: .automatic)
            }
            
        case .delete:
            if let oldIndexPathToDelete = indexPath {
                let adjustedIndexPath = IndexPath(row: oldIndexPathToDelete.row, section: 1)
                tableView.deleteRows(at: [adjustedIndexPath], with: .automatic)
            }
            
        case .update:
            if let indexPath = indexPath {
                let adjustedIndexPath = IndexPath(row: indexPath.row, section: 1)
                
                if let cell = tableView.cellForRow(at: adjustedIndexPath) as? QuakeCell {
                    if let quake = fetchedResultsController?.object(at: adjustedIndexPath) as? Quake {
                        cell.configure(quake)
                    }
                }
            }
            
        case .move:
            if let newIndexPathToInsert = newIndexPath, let oldIndexPathToDelete = indexPath {
                let newAdjustedIndexPath = IndexPath(row: newIndexPathToInsert.row, section: 1)
                let oldAdjustedIndexPath = IndexPath(row: oldIndexPathToDelete.row, section: 1)

                tableView.deleteRows(at: [oldAdjustedIndexPath], with: .automatic)
                tableView.insertRows(at: [newAdjustedIndexPath], with: .automatic)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

extension ListViewController: LocationFinderViewControllerDelegate
{
    
    // MARK: - LocationFinderViewController Delegate
    func locationFinderViewControllerDidSelectPlace(_ placemark: CLPlacemark) {
        dismiss(animated: true, completion: nil)
        
        TelemetryController.sharedController.logQuakeFinderDidSelectLocation(placemark.cityStateString())
        
        SettingsController.sharedController.lastSearchedPlace = placemark
        SettingsController.sharedController.lastLocationOption = nil
        
        PersistentController.sharedController.deleteAllQuakes()
        
        fetchQuakes()
    }
    
    func locationFinderViewControllerDidSelectOption(_ option: LocationOption) {
        dismiss(animated: true, completion: nil)
        
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
    func mapViewControllerDidFinishFetch(_ sucess: Bool, withPlace placemark: CLPlacemark) {
        if sucess {
            setTitleButtonText("\(placemark.cityStateString())")
        }
        
        if !sucess && fetchedResultsController?.fetchedObjects?.count == 0 && tableView.numberOfRows(inSection: 0) == 0 {
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
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator?.presenting = false
        return transitionAnimator
    }
    
}
