
import UIKit
import MapKit
import CoreData
import CoreLocation
import SafariServices
import GoogleMobileAds

class ListViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var adContainerView: UIView!
    @IBOutlet var noQuakesTitleLabel: UILabel!
    @IBOutlet var noQuakesBodyLabel: UILabel!
    @IBOutlet var adContainerViewHeightConstraint: NSLayoutConstraint!
    
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
    
    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refresher = UIRefreshControl()
        
        refresher.tintColor = StyleController.contrastColor
        refresher.backgroundColor = StyleController.backgroundColor
        refresher.addTarget(self, action: #selector(ListViewController.fetchQuakes), for: .valueChanged)
        
        return refresher
    }()
    
    fileprivate let locationHelper = LocationHelper()
    fileprivate lazy var defaults = UserDefaults.standard
    fileprivate var transitionAnimator: TextBarAnimator?
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var nativeExpressAdView: GADNativeExpressAdView!

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
        
        locationHelper.delegate = self
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        nativeExpressAdView = GADNativeExpressAdView()
        nativeExpressAdView.delegate = self
        nativeExpressAdView.rootViewController = self
        nativeExpressAdView.adUnitID = "ca-app-pub-6493864895252732/5256701203"
        nativeExpressAdView.backgroundColor = StyleController.backgroundColor
        nativeExpressAdView.translatesAutoresizingMaskIntoConstraints = false
        
        adContainerView.addSubview(nativeExpressAdView)
        adContainerView.backgroundColor = StyleController.backgroundColor
        adContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": nativeExpressAdView]))
        adContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": nativeExpressAdView]))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = QuakeCell.cellHeight
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.register(UINib(nibName: QuakeCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: QuakeCell.reuseIdentifier)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        }
        else {
            tableView.addSubview(refreshControl)
        }
        
        fetchedResultsController = {
            let moc = PersistentController.sharedController.moc
            
            let fetchRequest = Quake.fetchRequest(moc, predicate: nil, sortedBy: "timestamp", ascending: false)
            fetchRequest.fetchBatchSize = 20
            
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "quakes")
        }()
        fetchedResultsController?.delegate = self
        
        registerForPreviewing(with: self, sourceView: tableView)
        
        beginObserving()
        preformFetch()
        fetchQuakes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        
        if !SettingsController.sharedController.hasSupported {
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            nativeExpressAdView.load(request)
        }
    }
    
    fileprivate func preformFetch() {
        do {
            try fetchedResultsController?.performFetch()
            if navigationItem.rightBarButtonItem?.isEnabled == false {
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
        catch let error {
            print("Error fetching for the results controller: \(error)")
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    fileprivate func setTitleButtonText(_ textToSet: String) {
        titleViewButton.setTitle(textToSet, for: UIControlState())
        titleViewButton.sizeToFit()
    }
    
    func presentFinder() {
        titleViewButton.isHidden = true
        transitionAnimator = TextBarAnimator(duration: 0.3, presentingViewController: true, originatingFrame: titleViewButton.frame) {
            self.titleViewButton.isHidden = false
        }
        
        let finderVC = LocationFinderViewController()
        finderVC.delegate = self
        finderVC.transitioningDelegate = self
        present(finderVC, animated: true, completion: nil)
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
    
    // MARK: - Notifications
    func applicationDidEnterForeground() {
        tableView.reloadData()
    }
    
    func settingsDidPurchaseAdRemoval() {
        adContainerViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.23, animations: {
            self.view.layoutIfNeeded()
        })
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
        guard NetworkUtility.internetReachable() else { return }
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
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
            return
        }
        
        tableView.isHidden = false
        
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
                if let current = locationHelper.currentLocation {
                    setTitleButtonText("\(SettingsController.sharedController.cachedAddress!.cityStateString())")
                    
                    NetworkClient.sharedClient.getQuakesByLocation(current.coordinate) { quakes, error in
                        self.commonFinishedFetch(quakes)
                    }
                }
                else {
                    setTitleButtonText("Locating...")
                    locationHelper.startHelper()
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
    
    // MARK: - Helpers
    
    fileprivate func commonFinishedFetch(_ quakes: [ParsedQuake]?) {
        if let recievedQuakes = quakes, recievedQuakes.count > 0 {
            PersistentController.sharedController.saveQuakes(recievedQuakes)
        }
        
        let fetchedCount = (fetchedResultsController?.fetchedObjects?.count) ?? 0
        
        if fetchedCount > 0 {
            tableView.isHidden = false
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else {
            tableView.isHidden = true
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }
    
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return QuakeCell.cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: QuakeCell.reuseIdentifier) as? QuakeCell else {
            fatalError("Expected to dequeue a 'QuakeCell'.")
        }
        
        if let quake = fetchedResultsController?.fetchedObjects?[indexPath.row] as? Quake {
            cell.configure(quake)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let quake = fetchedResultsController?.fetchedObjects?[indexPath.row] as? Quake {
            navigationController?.pushViewController(DetailViewController(quake: quake), animated: true)
        }
    }
    
    // MARK: - UITableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let objectCount = fetchedResultsController?.fetchedObjects?.count ?? 0
        return objectCount
    }
    
}

extension ListViewController: LocationHelperDelegate {
    
    func locationHelperFailedWithError(error: LocationHelperError) {
        switch error {
            
        case .auth:
            SettingsController.sharedController.lastLocationOption = nil
            presentFinder()
            
        case .location:
            if let cachedAddress = SettingsController.sharedController.cachedAddress {
                setTitleButtonText(cachedAddress.cityStateString())
            }
            else {
                setTitleButtonText("Location Error")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(2 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                    self.presentFinder()
                }
            }
            
        case .placemark:
            setTitleButtonText("Location Error")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(2 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                self.presentFinder()
            }
            
        }
    }
    
    func locationHelperRecievedLocation(location: CLLocation) {
        
    }
    
    func locationHelperRecievedPlacemark(placemark: CLPlacemark) {
        SettingsController.sharedController.cachedAddress = placemark
        setTitleButtonText("\(placemark.cityStateString())")
        fetchQuakes()
    }
    
}

extension ListViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: - NSFetchedResultsController Delegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard navigationController?.topViewController is ListViewController else { return }
        
        switch type {
        case .insert:
            if let newIndexPathToInsert = newIndexPath {
                tableView.insertRows(at: [newIndexPathToInsert], with: .automatic)
            }
            
        case .delete:
            if let oldIndexPathToDelete = indexPath {
                tableView.deleteRows(at: [oldIndexPathToDelete], with: .automatic)
            }
            
        case .update:
            if let updatedIndexPath = indexPath {
                if let cell = tableView.cellForRow(at: updatedIndexPath) as? QuakeCell {
                    if let quake = fetchedResultsController?.object(at: updatedIndexPath) as? Quake {
                        cell.configure(quake)
                    }
                }
            }
            
        case .move:
            if let newIndexPathToInsert = newIndexPath, let oldIndexPathToDelete = indexPath {
                tableView.deleteRows(at: [oldIndexPathToDelete], with: .automatic)
                tableView.insertRows(at: [newIndexPathToInsert], with: .automatic)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

extension ListViewController: LocationFinderViewControllerDelegate {
    
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

extension ListViewController: MapViewControllerDelegate {
    
    // MARK: - MapViewController Delegate
    func mapViewControllerDidFinishFetch(_ sucess: Bool, withPlace placemark: CLPlacemark) {
        if sucess {
            setTitleButtonText("\(placemark.cityStateString())")
        }
        
        let fetchedCount = (fetchedResultsController?.fetchedObjects?.count) ?? 0
        
        if !sucess && fetchedCount == 0 {
            tableView.isHidden = true
        }
        else {
            tableView.isHidden = false
        }
    }
    
}

extension ListViewController: UIViewControllerTransitioningDelegate {
    
    // MARK: - UIViewControllerTransitioning Delegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator?.presenting = false
        return transitionAnimator
    }
    
}

extension ListViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRow(at: location) {
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            if let quake = fetchedResultsController?.object(at: indexPath) as? Quake {
                let vc = PeekableDetailViewController(quake: quake)
                vc.delegate = self
                vc.preferredContentSize = CGSize(width: 0, height: 400)
                return vc
            }
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let peekVC = viewControllerToCommit as? PeekableDetailViewController {
            let detailVC = DetailViewController(quake: peekVC.quakeToDisplay)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
}

extension ListViewController: PeekableDetailViewControllerDelegate {
    
    func peekableViewController(viewController: PeekableDetailViewController, didSelect actionType: PeekableActionType) {
        let quakeToDisplay = viewController.quakeToDisplay
        guard let urlString = quakeToDisplay.weblink, let url = URL(string: urlString) else { return }

        switch actionType {
        case .share:
            let options = MKMapSnapshotOptions()
            options.region = MKCoordinateRegion(center: quakeToDisplay.coordinate, span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2))
            options.size = viewController.mapView.frame.size
            options.scale = UIScreen.main.scale
            options.mapType = .hybrid
            
            MKMapSnapshotter(options: options).start (completionHandler: { snapshot, error in
                let prompt = "A \(Quake.magnitudeFormatter.string(from: NSNumber(value: quakeToDisplay.magnitude))!) magnitude earthquake happened \(quakeToDisplay.timestamp.relativeString()) ago near \(quakeToDisplay.name.components(separatedBy: " of ").last!)."
                var items: [Any] = [prompt, url, quakeToDisplay.location]
                
                if let shot = snapshot, error == nil {
                    let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                    let image = shot.image
                    
                    UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                    image.draw(at: CGPoint.zero)
                    
                    let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
                    var point = shot.point(for: quakeToDisplay.coordinate)
                    if visibleRect.contains(point) {
                        point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                        point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                        pin.image?.draw(at: point)
                    }
                    
                    if let compositeImage = UIGraphicsGetImageFromCurrentImageContext() {
                        items.append(compositeImage)
                    }
                    UIGraphicsEndImageContext()
                }
                
                
                DispatchQueue.main.async {
                    self.present(UIActivityViewController(activityItems: items, applicationActivities: nil), animated: true, completion: { _ in
                        TelemetryController.sharedController.logQuakeShare()
                    })
                }
            })
            
        case .felt:
            let safariVC = SFSafariViewController(url: URL(string: "\(urlString)#tellus")!)
            
            if #available(iOS 10.0, *) {
                safariVC.preferredControlTintColor = quakeToDisplay.severityColor
            }
            else {
                safariVC.view.tintColor = quakeToDisplay.severityColor
            }
            
            DispatchQueue.main.async {
                self.present(safariVC, animated: true, completion: { _ in
                    TelemetryController.sharedController.logQuakeOpenedInBrowser()
                })
            }
            
        case .open:
            let safariVC = SFSafariViewController(url: url)
            
            if #available(iOS 10.0, *) {
                safariVC.preferredControlTintColor = quakeToDisplay.severityColor
            }
            else {
                safariVC.view.tintColor = quakeToDisplay.severityColor
            }
            
            DispatchQueue.main.async {
                self.present(safariVC, animated: true, completion: { _ in
                    TelemetryController.sharedController.logQuakeOpenedInBrowser()
                })
            }

        }
    }
    
}

extension ListViewController: GADNativeExpressAdViewDelegate {
    
    // MARK: - GADBannerView Delegate
    func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
        adContainerViewHeightConstraint.constant = 85.0
        UIView.animate(withDuration: 0.23, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func nativeExpressAdView(_ nativeExpressAdView: GADNativeExpressAdView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Native ad view 'didFailToReceiveAdWithError' | Error: \(error)")
        adContainerViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.23, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
}
