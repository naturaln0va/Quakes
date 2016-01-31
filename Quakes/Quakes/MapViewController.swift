
import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func mapViewControllerDidFinishFetch(sucess: Bool, withPlace placemark: CLPlacemark)
}

class MapViewController: UIViewController
{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchAreaButton: UIButton!
    @IBOutlet weak var searchAreaButtonBottomConstraint: NSLayoutConstraint!
    
    var quakesToDisplay: [Quake]?
    var quakeToDisplay: Quake?
    var nearbyCitiesToDisplay: [ParsedNearbyCity]?
    
    var delegate: MapViewControllerDelegate?
    
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
    
    required init?(coder aDecoder: NSCoder) {
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
                    self.fetchQuakesAndDisplay()
                }
            }
            
            self.delegate?.mapViewControllerDidFinishFetch(sucess, withPlace: placemark)
            
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
        
        self.searchAreaButton.setTitle("Searching...", forState: .Normal)
        
        NetworkUtility.networkOperationStarted()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) { places, error in
            NetworkUtility.networkOperationFinished()
            if let place = places?.first where error == nil {
                if let _ = place.location {
                    self.fetchNewQuakesForPlace(place)
                }
                else {
                    self.searchAreaButton.setTitle("Failed Searching Location", forState: .Normal)
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
                    }
                }
            }
            else {
                self.searchAreaButton.setTitle("Failed Searching Location", forState: .Normal)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.searchAreaButton.setTitle("Search This Area", forState: .Normal)
                }
            }
        }
    }
    
    func recenterMapButtonPressed() {
        refreshMapAnimated(true)
    }
    
    func detailButtonPressed(sender: UIButton) {
        if let quakes = quakesToDisplay, let index = quakes.indexOf({ $0.hashValue == sender.tag }) {
            navigationController?.pushViewController(QuakeDetailViewController(quake: quakes[index]), animated: true)
        }
    }
    
    func refreshMapAnimated(animated: Bool) {
        var quakesToShowOnMap = [Quake]()
        
        if let quakes = quakesToDisplay {
            quakesToShowOnMap.appendContentsOf(quakes)
        }
        else if let quake = quakeToDisplay {
            quakesToShowOnMap.append(quake)
        }
        
        if mapView.annotations.count <= 1 {
            mapView.addAnnotations(quakesToShowOnMap)
            if let cities = nearbyCitiesToDisplay {
                mapView.addAnnotations(cities)
            }
        }
        
        if let userLocation = mapView.userLocation.location where quakesToShowOnMap.count == 0 {
            let region = MKCoordinateRegion(center: userLocation.coordinate, span:
                MKCoordinateSpan(
                    latitudeDelta: 5.5,
                    longitudeDelta: 5.5
                )
            )
            
            mapView.setVisibleMapRect(region.mapRectForCoordinateRegion(), animated: animated)
            return
        }
        
        if SettingsController.sharedController.isLocationOptionWorldOrMajor() {
            guard let latestQuake = quakesToShowOnMap.sort({ $0.timestamp.timeIntervalSince1970 > $1.timestamp.timeIntervalSince1970 }).first else {
                print("WARNING: There was not a sorted quake to center on.")
                return
            }
            
            var coordToCenterUpon = CLLocationCoordinate2D()
            
            if let userLocation = mapView.userLocation.location {
                coordToCenterUpon = userLocation.coordinate
            }
            else {
                coordToCenterUpon = latestQuake.coordinate
            }
            
            mapView.setCenterCoordinate(coordToCenterUpon, animated: true)
        }
        else {
            var locations = quakesToShowOnMap.map { $0.location }
            
            if let cities = nearbyCitiesToDisplay {
                locations.appendContentsOf(cities.map {$0.location })
            }
            
            var topLeftCoord = CLLocationCoordinate2D(
                latitude: -90,
                longitude: 180
            )
            var bottomRightCoord = CLLocationCoordinate2D(
                latitude: 90,
                longitude: -180
            )
            
            for location in locations {
                topLeftCoord.latitude = max(
                    topLeftCoord.latitude,
                    location.coordinate.latitude
                )
                topLeftCoord.longitude = min(
                    topLeftCoord.longitude,
                    location.coordinate.longitude
                )
                bottomRightCoord.latitude = min(
                    bottomRightCoord.latitude,
                    location.coordinate.latitude
                )
                bottomRightCoord.longitude = max(
                    bottomRightCoord.longitude,
                    location.coordinate.longitude
                )
            }
            
            let topLeftPoint = MKMapPointForCoordinate(topLeftCoord)
            let bottomRightPoint = MKMapPointForCoordinate(bottomRightCoord)
            
            let mapRect = MKMapRectMake(
                min(topLeftPoint.x, bottomRightPoint.x),
                min(topLeftPoint.y, bottomRightPoint.y),
                abs(topLeftPoint.x - bottomRightPoint.x),
                abs(topLeftPoint.y - bottomRightPoint.y)
            )
            
            let fittedRect = mapView.mapRectThatFits(mapRect, edgePadding: UIEdgeInsets(top: 55, left: 27, bottom: 55, right: 27))
            mapView.setVisibleMapRect(fittedRect, animated: animated)
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
        if annotation is Quake {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(Quake))
            annotationView.enabled = true
            annotationView.animatesDrop = false
            annotationView.canShowCallout = true
            
            if nearbyCitiesToDisplay == nil {
                let detailButton = UIButton(type: .Custom)
                detailButton.tag = (annotation as! Quake).hashValue
                detailButton.setImage(UIImage(named: "right-callout-arrow"), forState: .Normal)
                detailButton.addTarget(self, action: "detailButtonPressed:", forControlEvents: .TouchUpInside)
                detailButton.sizeToFit()

                annotationView.rightCalloutAccessoryView = detailButton
            }
            
            annotationView.pinTintColor = (annotation as! Quake).severityColor
            
            return annotationView
        }
        else if annotation is ParsedNearbyCity {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(ParsedNearbyCity))
            
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.image = (annotation as! ParsedNearbyCity) == nearbyCitiesToDisplay!.first ? UIImage(named: "selected-city-map-pin") : UIImage(named: "city-map-pin")
            annotationView.tintColor = UIColor.redColor()
            
            return annotationView
        }
        else {
            print("The annotaion view that was parsed was an unexpected type: \(annotation.dynamicType)")
            return nil
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
