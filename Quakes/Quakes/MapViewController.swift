
import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate: class {
    func mapViewControllerDidFinishFetch(sucess: Bool, withPlace placemark: CLPlacemark)
}

class MapViewController: UIViewController
{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchAreaButton: UIButton!
    @IBOutlet weak var searchAreaButtonBottomConstraint: NSLayoutConstraint!
    
    private var quakesToDisplay: [Quake]?
    private var quakeToDisplay: Quake?
    private var nearbyCitiesToDisplay: [ParsedNearbyCity]?
    private var coordinateToCenterOn: CLLocationCoordinate2D?
    private var currentlySearching = false
    
    weak var delegate: MapViewControllerDelegate?
    
    var shouldContinueUpdatingUserLocation = true
    let manager = CLLocationManager()
    let geocoder = CLGeocoder()
    
    init(quakeToDisplay quake: Quake?, nearbyCities: [ParsedNearbyCity]?) {
        super.init(nibName: String(MapViewController), bundle: nil)
        
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
        super.init(nibName: String(MapViewController), bundle: nil)
        title = "Map"
        coordinateToCenterOn = location
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        searchAreaButtonBottomConstraint.constant = -50
        view.layoutIfNeeded()
        
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "center-bar-button"),
            style: .Plain,
            target: self,
            action: "recenterMapButtonPressed"
        )
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
        
        if nearbyCitiesToDisplay != nil {
            refreshMapAnimated(true)
        }
        else {
            fetchQuakesAndDisplay()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NetworkUtility.cancelCurrentNetworkRequests()
        
        if geocoder.geocoding {
            geocoder.cancelGeocode()
        }
    }
    
    private func fetchQuakesAndDisplay()
    {
        do {
            quakesToDisplay = try Quake.objectsInContext(PersistentController.sharedController.moc)
            
            if quakesToDisplay != nil {
                refreshMapAnimated(true)
            }
        }
        catch {
            print("Error loading quakes from world persistent store \(error)")
        }
    }
    
    private func fetchNewQuakesForPlace(placemark: CLPlacemark) {
        guard NetworkUtility.internetReachable() else {
            self.currentlySearching = false
            self.searchAreaButton.setTitle("No Internet Connection", forState: .Normal)
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
            }
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
            
            if sucess {
                self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
            }
            else {
                self.searchAreaButton.setTitle("No Quakes In This Area", forState: .Normal)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func searchButtonPressed() {
        guard NetworkUtility.internetReachable() else { return }
        guard !currentlySearching else { return }
        
        self.searchAreaButton.setTitle("Searching...", forState: .Normal)
        currentlySearching = true
        
        NetworkUtility.networkOperationStarted()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) { places, error in
            NetworkUtility.networkOperationFinished()
            if let place = places?.first where error == nil {
                if let _ = place.location {
                    self.fetchNewQuakesForPlace(place)
                }
                else {
                    self.currentlySearching = false
                    self.searchAreaButton.setTitle("Failed Searching Location", forState: .Normal)
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
                    }
                }
            }
            else {
                self.currentlySearching = false
                self.searchAreaButton.setTitle("Failed Searching Location", forState: .Normal)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
                }
            }
        }
    }
    
    func recenterMapButtonPressed() {
        if coordinateToCenterOn != nil {
            coordinateToCenterOn = nil
            refreshMapAnimated(true)
        }
        else if let userLocation = mapView.userLocation.location {
            mapView.setCenterCoordinate(userLocation.coordinate, animated: true)
        }
    }
        
    func refreshMapAnimated(animated: Bool) {
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

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        guard NetworkUtility.internetReachable() else {
            return
        }

        guard nearbyCitiesToDisplay == nil && quakeToDisplay == nil else {
            return
        }
        
        if mapView.region.span.latitudeDelta < 7 {
            searchAreaButtonBottomConstraint.constant = 0
            UIView.animateWithDuration(0.345) {
                self.view.layoutIfNeeded()
            }
        }
        else {
            searchAreaButtonBottomConstraint.constant = -50
            UIView.animateWithDuration(0.345) {
                self.view.layoutIfNeeded()
            }
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
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let quakes = quakesToDisplay, let index = quakes.indexOf({ $0.hash == control.tag }) {
            navigationController?.popToRootViewControllerAnimated(true)
            navigationController?.pushViewController(QuakeDetailViewController(quake: quakes[index]), animated: true)
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate
{
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}
