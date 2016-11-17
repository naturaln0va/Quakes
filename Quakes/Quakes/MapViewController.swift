
import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate: class {
    func mapViewControllerDidFinishFetch(_ sucess: Bool, withPlace placemark: CLPlacemark)
}

class MapViewController: UIViewController {
    
    fileprivate lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsScale = true
        mapView.showsCompass = true
        return mapView
    }()
    
    fileprivate lazy var spaceBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()
    fileprivate lazy var locationBarButtonItem: MKUserTrackingBarButtonItem = {
        return MKUserTrackingBarButtonItem(mapView: self.mapView)
    }()
    fileprivate lazy var searchBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(MapViewController.searchButtonPressed))
    }()
    fileprivate lazy var messageLabelBarButtonItem: UIBarButtonItem = {
        let messageLabel = UILabel()
        messageLabel.font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightRegular)
        messageLabel.numberOfLines = 2
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        return UIBarButtonItem(customView: messageLabel)
    }()
    
    fileprivate lazy var filterHeaderView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true
        return containerView
    }()
    fileprivate lazy var filterTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20.0, weight: UIFontWeightLight)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.sizeToFit()
        return label
    }()
    fileprivate lazy var filterSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = UIColor.black
        slider.minimumValue = 1
        slider.maximumValue = 30
        slider.value = 30
        slider.addTarget(self, action: #selector(MapViewController.filterSliderChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(MapViewController.filterSliderEnded(_:)), for: .touchUpInside)
        return slider
    }()
    
    fileprivate var quakesToDisplay: [Quake]?
    fileprivate var quakeToDisplay: Quake?
    fileprivate var nearbyCitiesToDisplay: [ParsedNearbyCity]?
    fileprivate var coordinateToCenterOn: CLLocationCoordinate2D?
    fileprivate var filterContainerViewTopConstraint: NSLayoutConstraint?
    
    weak var delegate: MapViewControllerDelegate?
    
    fileprivate var firstLayout = true
    fileprivate var firstMapLoad = true
    fileprivate var currentlySearching = false
    fileprivate var shouldContinueUpdatingUserLocation = true
    
    fileprivate lazy var manager = CLLocationManager()
    fileprivate lazy var geocoder = CLGeocoder()
    
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
        
        navigationController?.isToolbarHidden = false
        toolbarItems = [locationBarButtonItem, spaceBarButtonItem]
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
        
        if nearbyCitiesToDisplay == nil && quakeToDisplay == nil && SettingsController.sharedController.lastLocationOption != LocationOption.World.rawValue {
            filterHeaderView.addSubview(filterTitleLabel)
            filterHeaderView.addSubview(filterSlider)
            
            let views = ["slider": filterSlider, "label": filterTitleLabel] as [String : Any]
            filterHeaderView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-30-[slider]-30-|", options: [], metrics: nil, views: views))
            filterHeaderView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[label]-15-|", options: [], metrics: nil, views: views))
            filterHeaderView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[label]-4-[slider]-8-|", options: [], metrics: nil, views: views))
            
            view.addSubview(filterHeaderView)
            view.addSubview(mapView)
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[container]|", options: [], metrics: nil, views: ["container": filterHeaderView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[map]|", options: [], metrics: nil, views: ["map": mapView]))
            
            filterContainerViewTopConstraint = NSLayoutConstraint(item: filterHeaderView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
            view.addConstraint(filterContainerViewTopConstraint!)
            
            view.addConstraint(NSLayoutConstraint(item: filterHeaderView, attribute: .bottom, relatedBy: .equal, toItem: mapView, attribute: .top, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: mapView, attribute: .bottom, relatedBy: .equal, toItem: mapView.superview, attribute: .bottom, multiplier: 1, constant: 0))
        }
        else {
            view.addSubview(mapView)
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[map]|", options: [], metrics: nil, views: ["map": mapView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[map]|", options: [], metrics: nil, views: ["map": mapView]))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.set(bottomDividerLineHidden: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.set(bottomDividerLineHidden: false)
        navigationController?.isToolbarHidden = true
        
        if geocoder.isGeocoding {
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
    
    fileprivate func fetchQuakesAndDisplay() {
        do {
            filterTitleLabel.text = ""
            quakesToDisplay = try Quake.objectsInContext(PersistentController.sharedController.moc)
            var minDays = 0
            var maxDays = 0
            
            if let quakes = quakesToDisplay {
                let sortedQuakes = quakes.sorted { quakeTuple in
                    let quakeOne = quakeTuple.0
                    let quakeTwo = quakeTuple.1
                    
                    return Date().daysSince(quakeOne.timestamp) < Date().daysSince(quakeTwo.timestamp)
                }
                if let lastSortedQuake = sortedQuakes.last {
                    maxDays = Date().daysSince(lastSortedQuake.timestamp)
                    if maxDays == 1 {
                        DispatchQueue.main.async {
                            self.filterContainerViewTopConstraint?.constant = -self.filterHeaderView.frame.height
                            self.view.layoutIfNeeded()
                        }
                    }
                    else if maxDays < 29 {
                        DispatchQueue.main.async {
                            self.filterContainerViewTopConstraint?.constant = 0
                            self.view.layoutIfNeeded()
                        }
                        
                        filterSlider.maximumValue = Float(maxDays)
                    }
                }
                if let firstSortedQuake = sortedQuakes.first {
                    minDays = Date().daysSince(firstSortedQuake.timestamp)
                    if minDays > 0 {
                        filterSlider.minimumValue = Float(minDays)
                    }
                }
                
                if minDays == maxDays {
                    DispatchQueue.main.async {
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
    
    fileprivate func showMessageWithText(_ text: String, shouldAutoDismiss dismiss: Bool) {
        let messageLabel = UILabel()
        messageLabel.font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightRegular)
        messageLabel.numberOfLines = 2
        messageLabel.textAlignment = .center
        messageLabel.text = text
        messageLabel.sizeToFit()
        messageLabelBarButtonItem = UIBarButtonItem(customView: messageLabel)
        
        if let items = navigationController?.toolbar.items, items.contains(searchBarButtonItem) {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, messageLabelBarButtonItem, spaceBarButtonItem, searchBarButtonItem], animated: true)
        }
        else {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, messageLabelBarButtonItem, spaceBarButtonItem], animated: true)
        }
        
        if dismiss {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(2 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                if let items = self.navigationController?.toolbar.items, items.contains(self.searchBarButtonItem) {
                    self.navigationController?.toolbar.setItems([self.locationBarButtonItem, self.spaceBarButtonItem, self.searchBarButtonItem], animated: true)
                }
                else {
                    self.navigationController?.toolbar.setItems([self.locationBarButtonItem, self.spaceBarButtonItem], animated: true)
                }
            }
        }
    }
    
    fileprivate func fetchNewQuakesForPlace(_ placemark: CLPlacemark) {
        guard NetworkUtility.internetReachable() else {
            self.currentlySearching = false
            showMessageWithText("No Internet Connection", shouldAutoDismiss: false)
            return
        }
        
        NetworkClient.sharedClient.getQuakesByLocation(placemark.location!.coordinate) { quakes, error in
            var sucess = false
            if let quakes = quakes, error == nil {
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
        
        let loadingActivityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingActivityView.color = StyleController.contrastColor
        loadingActivityView.startAnimating()
        
        let loadingBarButton = UIBarButtonItem(customView: loadingActivityView)
        if let items = navigationController?.toolbar.items, items.contains(messageLabelBarButtonItem) {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, messageLabelBarButtonItem, spaceBarButtonItem, loadingBarButton], animated: false)
        }
        else {
            navigationController?.toolbar.setItems([locationBarButtonItem, spaceBarButtonItem, loadingBarButton], animated: false)
        }
        
        NetworkUtility.networkOperationStarted()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) { places, error in
            NetworkUtility.networkOperationFinished()
            if let place = places?.first, error == nil {
                if let _ = place.location {
                    self.fetchNewQuakesForPlace(place)
                    if let items = self.navigationController?.toolbar.items, items.contains(self.messageLabelBarButtonItem) {
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
    
    func filterSliderChanged(_ sender: UISlider) {
        refreshFilterLabel()
    }
    
    func filterSliderEnded(_ sender: UISlider) {
        TelemetryController.sharedController.logQuakeMapFiltered()
        
        if let quakes = quakesToDisplay {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(quakes.filter{ Date().daysSince($0.timestamp) < Int(sender.value) })
        }
    }
    
    fileprivate func refreshFilterLabel() {
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
            
    fileprivate func refreshMapAnimated(_ animated: Bool) {
        var annotationsToShowOnMap = [MKAnnotation]()
        
        if let quakes = quakesToDisplay {
            annotationsToShowOnMap.append(contentsOf: (quakes as [MKAnnotation]))
        }
        else if let quake = quakeToDisplay {
            annotationsToShowOnMap.append(quake)
        }
        
        if let cities = nearbyCitiesToDisplay {
            annotationsToShowOnMap.append(contentsOf: (cities as [MKAnnotation]))
        }
        
        if mapView.annotations.count <= 1 {
            mapView.addAnnotations(annotationsToShowOnMap)
        }
        
        if let indexOfAnnotation = annotationsToShowOnMap.index(where: { $0.coordinate.latitude == coordinateToCenterOn?.latitude && $0.coordinate.longitude == coordinateToCenterOn?.longitude }), coordinateToCenterOn != nil {
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
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
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
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocation else { return }
        
        if let _ = userLocation.location {
            refreshMapAnimated(true)
            shouldContinueUpdatingUserLocation = false
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: String(annotation.hash)) {
            return annotationView
        }
        
        if annotation is Quake {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            annotationView.isEnabled = true
            annotationView.animatesDrop = false
            annotationView.canShowCallout = true
            
            if nearbyCitiesToDisplay == nil {
                let detailButton = UIButton(type: .custom)
                detailButton.tag = annotation.hash
                detailButton.setImage(UIImage(named: "detail-arrow"), for: UIControlState())
                detailButton.sizeToFit()
                
                annotationView.rightCalloutAccessoryView = detailButton
            }
            
            annotationView.pinTintColor = (annotation as! Quake).severityColor
            
            return annotationView
        }
        else if annotation is ParsedNearbyCity {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            
            annotationView.isEnabled = true
            annotationView.canShowCallout = true
            annotationView.image = (annotation as! ParsedNearbyCity) == nearbyCitiesToDisplay!.first ? UIImage(named: "selected-city-map-pin") : UIImage(named: "city-map-pin")
            annotationView.tintColor = UIColor.red
            
            return annotationView
        }
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if views.count == quakesToDisplay?.count {
            if firstMapLoad { firstMapLoad = false }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let quakes = quakesToDisplay, let index = quakes.index(where: { $0.hash == control.tag }) {
            _ = navigationController?.popToRootViewController(animated: true)
            navigationController?.pushViewController(DetailViewController(quake: quakes[index]), animated: true)
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate
{
    
    // MARK: - CLLocationManager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}
