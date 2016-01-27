
import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController
{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locateButton: UIButton!
    
    var quakesToDisplay: [Quake]?
    var quakeToDisplay: Quake?
    var nearbyCitiesToDisplay: [ParsedNearbyCity]?
    
    var shouldContinueUpdatingUserLocation = true
    let manager = CLLocationManager()
    
    init(quakeToDisplay quake: Quake?, nearbyCities: [ParsedNearbyCity]?) {
        super.init(nibName: String(MapViewController), bundle: nil)
        
        if nearbyCities != nil && quake != nil {
            quakeToDisplay = quake
            self.nearbyCitiesToDisplay = nearbyCities
            title = "Nearby Cities"
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.delegate = self
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
        
        locateButton.addTarget(self, action: "recenterMapButtonPressed", forControlEvents: .TouchUpInside)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if nearbyCitiesToDisplay == nil {
            fetchQuakesAndDisplay()
        }
        else if let quake = quakeToDisplay, let citiesToDisplay = nearbyCitiesToDisplay {
            refreshMapWithQuakes([quake], cities: citiesToDisplay, animated: true)
        }
    }
    
    func fetchQuakesAndDisplay()
    {
        do {
            quakesToDisplay = try Quake.objectsInContext(PersistentController.sharedController.moc)
            
            if let quakes = quakesToDisplay {
                refreshMapWithQuakes(quakes, cities: nil, animated: false)
                title = "\(quakes.count) Earthquakes"
            }
        }
        catch {
            print("Error loading quakes from persistent store \(error)")
        }
    }
    
    // MARK: - Actions
    func recenterMapButtonPressed() {
        if let quakes = quakesToDisplay {
            refreshMapWithQuakes(quakes, cities: nil, animated: true)
        }
        else if let quake = quakeToDisplay, let citiesToDisplay = nearbyCitiesToDisplay {
            refreshMapWithQuakes([quake], cities: citiesToDisplay, animated: true)
        }
    }
    
    func detailButtonPressed(sender: UIButton) {
        if let quakes = quakesToDisplay, let index = quakes.indexOf({ $0.hashValue == sender.tag }) {
            navigationController?.pushViewController(QuakeDetailViewController(quake: quakes[index]), animated: true)
        }
    }
    
    func refreshMapWithQuakes(quakes: [Quake], cities: [ParsedNearbyCity]?, animated: Bool) {
        if mapView.annotations.count == 0 {
            mapView.addAnnotations(quakes)
            if let cities = cities {
                mapView.addAnnotations(cities)
            }
        }
        
        if let citiesToDisplay = cities {
            var locations = citiesToDisplay.map { $0.location }
            locations.append(quakes.first!.location)
            
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
        else {
            if SettingsController.sharedController.lastLocationOption == LocationOption.Nearby.rawValue || SettingsController.sharedController.lastSearchedPlace != nil {
                var locations = quakes.map { $0.location }
                
                if let userLocation = mapView.userLocation.location where SettingsController.sharedController.lastLocationOption == LocationOption.Nearby.rawValue {
                    locations.append(userLocation)
                }
                
                var mapRect = MKMapRect()
                if locations.count == 1 {
                    let center = CLLocationCoordinate2D(
                        latitude: mapView.userLocation.location!.coordinate.latitude,
                        longitude: mapView.userLocation.location!.coordinate.longitude
                    )
                    mapRect = MKMapRect(origin: MKMapPoint(x: center.latitude, y: center.longitude), size: MKMapSize(width: 650, height: 650))
                }
                else {
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
                    
                    mapRect = MKMapRectMake(
                        min(topLeftPoint.x, bottomRightPoint.x),
                        min(topLeftPoint.y, bottomRightPoint.y),
                        abs(topLeftPoint.x - bottomRightPoint.x),
                        abs(topLeftPoint.y - bottomRightPoint.y)
                    )
                }
                
                let fittedRect = mapView.mapRectThatFits(mapRect, edgePadding: UIEdgeInsets(top: 55, left: 27, bottom: 55, right: 27))
                mapView.setVisibleMapRect(fittedRect, animated: animated)
            }
            else {
                var mapRect = MKMapRect()
                var centerPoint = CLLocationCoordinate2D()
                if let latestQuake = quakes.sort({ $0.timestamp.timeIntervalSince1970 > $1.timestamp.timeIntervalSince1970 }).first {
                    centerPoint = latestQuake.coordinate
                    mapRect = MKMapRect(
                        origin: MKMapPointMake(MKMapPointForCoordinate(latestQuake.coordinate).x / 2, MKMapPointForCoordinate(latestQuake.coordinate).y / 2),
                        size: MKMapSize(width: MKMapSizeWorld.width / 10, height: MKMapSizeWorld.height / 10)
                    )
                }
                else {
                    if let userLocation = mapView.userLocation.location {
                        centerPoint = userLocation.coordinate
                        mapRect = MKMapRect(
                            origin: MKMapPointForCoordinate(userLocation.coordinate),
                            size: MKMapSize(width: MKMapSizeWorld.width / 10, height: MKMapSizeWorld.height / 10)
                        )
                    }
                }
                
                mapView.setVisibleMapRect(mapRect, animated: false)
                mapView.setCenterCoordinate(centerPoint, animated: animated)
            }
        }
        
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocation else { return }
        
        if let _ = userLocation.location {
            if let quakes = quakesToDisplay {
                refreshMapWithQuakes(quakes, cities: nil, animated: true)
            }
            else if let quake = quakeToDisplay, let citiesToDisplay = nearbyCitiesToDisplay {
                refreshMapWithQuakes([quake], cities: citiesToDisplay, animated: true)
            }
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
            
            let detailButton = UIButton(type: .Custom)
            detailButton.tag = (annotation as! Quake).hashValue
            detailButton.setImage(UIImage(named: "right-callout-arrow"), forState: .Normal)
            detailButton.addTarget(self, action: "detailButtonPressed:", forControlEvents: .TouchUpInside)
            detailButton.sizeToFit()
            
            annotationView.rightCalloutAccessoryView = detailButton
            
            var colorForPin = StyleController.greenQuakeColor
            if (annotation as! Quake).magnitude >= 4.0 {
                colorForPin = StyleController.redQuakeColor
            }
            else if (annotation as! Quake).magnitude >= 3.0 {
                colorForPin = StyleController.orangeQuakeColor
            }
            else {
                colorForPin = StyleController.greenQuakeColor
            }
            
            annotationView.pinTintColor = colorForPin
            
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
