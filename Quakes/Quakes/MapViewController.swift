
import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate: class {
    func mapViewControllerDidFinishFetch(sucess: Bool, withPlace placemark: CLPlacemark)
}

class MapViewController: UIViewController
{
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsScale = true
        mapView.showsCompass = true
        return mapView
    }()
    
    private lazy var spaceBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }()
    private lazy var locationBarButtonItem: MKUserTrackingBarButtonItem = {
        return MKUserTrackingBarButtonItem(mapView: self.mapView)
    }()
    private lazy var searchBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: #selector(MapViewController.searchButtonPressed))
    }()
    private lazy var messageLabelBarButtonItem: UIBarButtonItem = {
        let messageLabel = UILabel()
        messageLabel.font = UIFont.systemFontOfSize(11.0, weight: UIFontWeightRegular)
        messageLabel.numberOfLines = 2
        messageLabel.textAlignment = .Center
        messageLabel.sizeToFit()
        return UIBarButtonItem(customView: messageLabel)
    }()
    
    private lazy var filterHeaderView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.whiteColor()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true
        return containerView
    }()
    private lazy var filterTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFontOfSize(20.0, weight: UIFontWeightLight)
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.sizeToFit()
        return label
    }()
    private lazy var filterSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = UIColor.blackColor()
        slider.minimumValue = 1
        slider.maximumValue = 30
        slider.value = 30
        slider.addTarget(self, action: #selector(MapViewController.filterSliderChanged(_:)), forControlEvents: .ValueChanged)
        slider.addTarget(self, action: #selector(MapViewController.filterSliderEnded(_:)), forControlEvents: .TouchUpInside)
        return slider
    }()
    
    private var quakesToDisplay: [Quake]?
    private var quakeToDisplay: Quake?
    private var nearbyCitiesToDisplay: [ParsedNearbyCity]?
    private var coordinateToCenterOn: CLLocationCoordinate2D?
    private var filterContainerViewTopConstraint: NSLayoutConstraint?
    
    weak var delegate: MapViewControllerDelegate?
    
    private var firstLayout = true
    private var firstMapLoad = true
    private var currentlySearching = false
    private var shouldContinueUpdatingUserLocation = true
    
    private lazy var manager = CLLocationManager()
    private lazy var geocoder = CLGeocoder()
    
    init(quakeToDisplay quake: Quake?, nearbyCities: [ParsedNearbyCity]?) {
        super.init(nibName: nil, bundle: nil)
        
        if nearbyCities != nil && quake != nil {
            quakeToDisplay = quake
            self.nearbyCitiesToDisplay = nearbyCities
            title = "Nearby Cities"
        }
        else {
            title = "Map"
        }
    }
    
    init(centeredOnLocation location: CLLocationCoordinate2D) {
        super.init(nibName: nil, bundle: nil)
        title = "Map"
        coordinateToCenterOn = location
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TelemetryController.sharedController.logQuakeMapOpened()
        
        navigationController?.toolbarHidden = false
        toolbarItems = [locationBarButtonItem, spaceBarButtonItem]
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
        
        if nearbyCitiesToDisplay == nil && quakeToDisplay == nil && SettingsController.sharedController.lastLocationOption != LocationOption.World.rawValue {
            filterHeaderView.addSubview(filterTitleLabel)
            filterHeaderView.addSubview(filterSlider)
            
            let views = ["slider": filterSlider, "label": filterTitleLabel]
            filterHeaderView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-30-[slider]-30-|", options: [], metrics: nil, views: views))
            filterHeaderView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-15-[label]-15-|", options: [], metrics: nil, views: views))
            filterHeaderView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[label]-4-[slider]-8-|", options: [], metrics: nil, views: views))
            
            view.addSubview(filterHeaderView)
            view.addSubview(mapView)
            
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[container]|", options: [], metrics: nil, views: ["container": filterHeaderView]))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: ["map": mapView]))
            
            filterContainerViewTopConstraint = NSLayoutConstraint(item: filterHeaderView, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0)
            view.addConstraint(filterContainerViewTopConstraint!)
            
            view.addConstraint(NSLayoutConstraint(item: filterHeaderView, attribute: .Bottom, relatedBy: .Equal, toItem: mapView, attribute: .Top, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mapView, attribute: .Bottom, relatedBy: .Equal, toItem: mapView.superview, attribute: .Bottom, multiplier: 1, constant: 0))
        }
        else {
            view.addSubview(mapView)
            
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: ["map": mapView]))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map]|", options: [], metrics: nil, views: ["map": mapView]))
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NetworkUtility.cancelCurrentNetworkRequests()
        navigationController?.toolbarHidden = true
        
        if geocoder.geocoding {
            geocoder.cancelGeocode()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if firstLayout {
            if nearbyCitiesToDisplay != nil {
                refreshMapAnimated(true)
            }
            else {
                fetchQuakesAndDisplay()
            }
            firstLayout = false
        }
    }
    
    private func fetchQuakesAndDisplay() {
        do {
            filterTitleLabel.text = ""
            quakesToDisplay = try Quake.objectsInContext(PersistentController.sharedController.moc)
            var minDays = 0
            var maxDays = 0
            
            if let quakes = quakesToDisplay {
                let sortedQuakes = quakes.sort { quakeTuple in
                    let quakeOne = quakeTuple.0
                    let quakeTwo = quakeTuple.1
                    
                    return NSDate().daysSince(quakeOne.timestamp) < NSDate().daysSince(quakeTwo.timestamp)
                }
                if let lastSortedQuake = sortedQuakes.last {
                    maxDays = NSDate().daysSince(lastSortedQuake.timestamp)
                    if maxDays == 1 {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.filterContainerViewTopConstraint?.constant = -self.filterHeaderView.frame.height
                            self.view.layoutIfNeeded()
                        }
                    }
                    else if maxDays < 29 {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.filterContainerViewTopConstraint?.constant = 0
                            self.view.layoutIfNeeded()
                        }
                        
                        filterSlider.maximumValue = Float(maxDays)
                    }
                }
                if let firstSortedQuake = sortedQuakes.first {
                    minDays = NSDate().daysSince(firstSortedQuake.timestamp)
                    if minDays > 0 {
                        filterSlider.minimumValue = Float(minDays)
                    }
                }
                
                if minDays == maxDays {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.filterContainerViewTopConstraint?.constant = -self.filterHeaderView.frame.height
                        self.view.layoutIfNeeded()
                    }
                }
                
                refreshFilterLabel()
                refreshMapAnimated(true)
            }
        }
        catch {
            print("Error loading quakes from persistent store \(error)")
        }
    }
    
    private func showMessageWithText(text: String, shouldAutoDismiss dismiss: Bool) {
        let messageLabel = UILabel()
        messageLabel.font = UIFont.systemFontOfSize(11.0, weight: UIFontWeightRegular)
        messageLabel.numberOfLines = 2
        messageLabel.textAlignment = .Center
        messageLabel.text = text
        messageLabel.sizeToFit()
        messageLabelBarButtonItem = UIBarButtonItem(customView: messageLabel)
        
        if let items = navigationController?.toolbar.items where items.contains(searchBarButtonItem) {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, messageLabelBarButtonItem, spaceBarButtonItem, searchBarButtonItem], animated: true)
        }
        else {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, messageLabelBarButtonItem, spaceBarButtonItem], animated: true)
        }
        
        if dismiss {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                if let items = self.navigationController?.toolbar.items where items.contains(self.searchBarButtonItem) {
                    self.navigationController?.toolbar.setItems([self.locationBarButtonItem, self.spaceBarButtonItem, self.searchBarButtonItem], animated: true)
                }
                else {
                    self.navigationController?.toolbar.setItems([self.locationBarButtonItem, self.spaceBarButtonItem], animated: true)
                }
            }
        }
    }
    
    private func fetchNewQuakesForPlace(placemark: CLPlacemark) {
        guard NetworkUtility.internetReachable() else {
            self.currentlySearching = false
            showMessageWithText("No Internet Connection", shouldAutoDismiss: false)
            return
        }
        
        NetworkUtility.networkOperationStarted()
        NetworkClient.sharedClient.getRecentQuakesByLocation(placemark.location!.coordinate) { quakes, error in
            NetworkUtility.networkOperationFinished()
            
            var sucess = false
            if let quakes = quakes where error == nil {
                sucess = quakes.count > 0
                
                if quakes.count > 0 {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    PersistentController.sharedController.deleteAllThenSaveQuakes(quakes)
                    
                    SettingsController.sharedController.lastSearchedPlace = placemark
                    SettingsController.sharedController.lastLocationOption = nil
                    
                    self.fetchQuakesAndDisplay()
                }
            }
            
            self.delegate?.mapViewControllerDidFinishFetch(sucess, withPlace: placemark)
            self.currentlySearching = false
            
            if !sucess {
                self.showMessageWithText("No Quakes", shouldAutoDismiss: true)
            }
        }
    }
    
    // MARK: - Actions
    func searchButtonPressed() {
        guard NetworkUtility.internetReachable() else { return }
        guard !currentlySearching else { return }
        
        currentlySearching = true
        
        let loadingActivityView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        loadingActivityView.color = StyleController.contrastColor
        loadingActivityView.startAnimating()
        
        let loadingBarButton = UIBarButtonItem(customView: loadingActivityView)
        if let items = navigationController?.toolbar.items where items.contains(messageLabelBarButtonItem) {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, messageLabelBarButtonItem, spaceBarButtonItem, loadingBarButton], animated: false)
        }
        else {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, loadingBarButton], animated: false)
        }
        
        NetworkUtility.networkOperationStarted()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) { places, error in
            NetworkUtility.networkOperationFinished()
            if let place = places?.first where error == nil {
                if let _ = place.location {
                    self.fetchNewQuakesForPlace(place)
                    if let items = self.navigationController?.toolbar.items where items.contains(self.messageLabelBarButtonItem) {
                        self.navigationController?.toolbar.setItems([self.locationBarButtonItem, self.spaceBarButtonItem, self.messageLabelBarButtonItem, self.spaceBarButtonItem, self.searchBarButtonItem], animated: true)
                    }
                    else {
                        self.navigationController?.toolbar.setItems([self.locationBarButtonItem, self.spaceBarButtonItem, self.searchBarButtonItem], animated: true)
                    }
                }
                else {
                    self.currentlySearching = false
                    self.showMessageWithText("Failed Searching Location", shouldAutoDismiss: true)
                }
            }
            else {
                self.currentlySearching = false
                self.showMessageWithText("Failed Searching Location", shouldAutoDismiss: true)
            }
        }
    }
    
    func filterSliderChanged(sender: UISlider) {
        refreshFilterLabel()
    }
    
    func filterSliderEnded(sender: UISlider) {
        TelemetryController.sharedController.logQuakeMapFiltered()
        
        if let quakes = quakesToDisplay {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(quakes.filter{ NSDate().daysSince($0.timestamp) < Int(sender.value) })
        }
    }
    
    private func refreshFilterLabel() {
        let wholeValue = Int(filterSlider.value)
        
        if wholeValue == 30 {
            filterTitleLabel.text = "Quakes from last month"
        }
        else if wholeValue == 21 {
            filterTitleLabel.text = "Quakes from the last 3 weeks"
        }
        else if wholeValue == 14 {
            filterTitleLabel.text = "Quakes from the last 2 weeks"
        }
        else if wholeValue == 7 {
            filterTitleLabel.text = "Quakes from last week"
        }
        else if wholeValue == 2 {
            filterTitleLabel.text = "Quakes from yesterday"
        }
        else if wholeValue == 1 {
            filterTitleLabel.text = "Quakes from today"
        }
        else {
            filterTitleLabel.text = "Quakes from the last \(wholeValue) days"
        }
    }
            
    private func refreshMapAnimated(animated: Bool) {
        var annotationsToShowOnMap = [MKAnnotation]()
        
        if let quakes = quakesToDisplay {
            annotationsToShowOnMap.appendContentsOf((quakes as [MKAnnotation]))
        }
        else if let quake = quakeToDisplay {
            annotationsToShowOnMap.append(quake)
        }
        
        if let cities = nearbyCitiesToDisplay {
            annotationsToShowOnMap.appendContentsOf((cities as [MKAnnotation]))
        }
        
        if mapView.annotations.count <= 1 {
            mapView.addAnnotations(annotationsToShowOnMap)
        }
        
        if let indexOfAnnotation = annotationsToShowOnMap.indexOf({ $0.coordinate.latitude == coordinateToCenterOn?.latitude && $0.coordinate.longitude == coordinateToCenterOn?.longitude }) where coordinateToCenterOn != nil {
            mapView.showAnnotations([annotationsToShowOnMap[indexOfAnnotation]], animated: true)
            return
        }
        
        if SettingsController.sharedController.lastLocationOption == LocationOption.Nearby.rawValue && nearbyCitiesToDisplay == nil {
            mapView.showAnnotations(mapView.annotations, animated: animated)
        }
        else if SettingsController.sharedController.isLocationOptionWorldOrMajor() && nearbyCitiesToDisplay == nil {
            mapView.showAnnotations(annotationsToShowOnMap, animated: animated)
        }
        else {
            mapView.showAnnotations(annotationsToShowOnMap, animated: animated)
        }
    }
    
}

extension MapViewController: MKMapViewDelegate
{
    
    // MARK: - MKMapView Delegate
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        guard NetworkUtility.internetReachable() else {
            return
        }

        guard nearbyCitiesToDisplay == nil && quakeToDisplay == nil else {
            return
        }
        
        if mapView.region.span.latitudeDelta < 6.125 {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, searchBarButtonItem], animated: true)
        }
        else {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem], animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocation else { return }
        
        if let _ = userLocation.location {
            refreshMapAnimated(true)
            shouldContinueUpdatingUserLocation = false
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(String(annotation.hash)) {
            return annotationView
        }
        
        if annotation is Quake {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            annotationView.enabled = true
            annotationView.animatesDrop = false
            annotationView.canShowCallout = true
            
            if nearbyCitiesToDisplay == nil {
                let detailButton = UIButton(type: .Custom)
                detailButton.tag = annotation.hash
                detailButton.setImage(UIImage(named: "detail-arrow"), forState: .Normal)
                detailButton.sizeToFit()
                
                annotationView.rightCalloutAccessoryView = detailButton
            }
            
            annotationView.pinTintColor = (annotation as! Quake).severityColor
            
            return annotationView
        }
        else if annotation is ParsedNearbyCity {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.image = (annotation as! ParsedNearbyCity) == nearbyCitiesToDisplay!.first ? UIImage(named: "selected-city-map-pin") : UIImage(named: "city-map-pin")
            annotationView.tintColor = UIColor.redColor()
            
            return annotationView
        }
        else {
            return nil
        }
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        if views.count == quakesToDisplay?.count {
            if firstMapLoad { firstMapLoad = false }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let quakes = quakesToDisplay, let index = quakes.indexOf({ $0.hash == control.tag }) {
            navigationController?.popToRootViewControllerAnimated(true)
            navigationController?.pushViewController(QuakeDetailViewController(quake: quakes[index]), animated: true)
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate
{
    
    // MARK: - CLLocationManager Delegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}
