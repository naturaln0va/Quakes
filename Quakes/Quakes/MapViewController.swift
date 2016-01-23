
import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController
{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locateButton: UIButton!
    
    var quakesToDisplay: [Quake]?
    var shouldContinueUpdatingUserLocation = true
    let manager = CLLocationManager()
    
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
        
        fetchQuakesAndDisplay()
    }
    
    func fetchQuakesAndDisplay()
    {
        do {
            quakesToDisplay = try Quake.objectsInContext(PersistentController.sharedController.moc)
            
            if let quakes = quakesToDisplay {
                refreshMapWithQuakes(quakes, animated: false)
            }
        }
        catch {
            print("Error loading quakes from persistent store \(error)")
        }
    }
    
    func recenterMapButtonPressed() {
        if let quakes = quakesToDisplay {
            refreshMapWithQuakes(quakes, animated: true)
        }
    }
    
    func refreshMapWithQuakes(quakes: [Quake], animated: Bool) {
        if let quakesBeingDisplayed = mapView.annotations as? [Quake] where quakesBeingDisplayed != quakes {
            mapView.removeAnnotations(quakesBeingDisplayed)
            mapView.addAnnotations(quakes)
        }
        else if mapView.annotations.count == 0 {
            mapView.addAnnotations(quakes)
        }
        
        if SettingsController.sharedContoller.lastLocationOption == LocationOption.Nearby.rawValue || SettingsController.sharedContoller.lastSearchedPlace != nil {
            var locations = quakes.map { $0.location }
            
            if let userLocation = mapView.userLocation.location where SettingsController.sharedContoller.lastLocationOption == LocationOption.Nearby.rawValue {
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

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocation else { return }
        
        if let _ = userLocation.location, let quakes = quakesToDisplay {
            refreshMapWithQuakes(quakes, animated: false)
            shouldContinueUpdatingUserLocation = false
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard let annotation = annotation as? Quake else {
            return nil
        }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Quake")
        annotationView.enabled = true
        annotationView.animatesDrop = false
        annotationView.canShowCallout = true
        
        var colorForPin = StyleController.greenQuakeColor
        if annotation.magnitude >= 4.0 {
            colorForPin = StyleController.redQuakeColor
        }
        else if annotation.magnitude >= 3.0 {
            colorForPin = StyleController.orangeQuakeColor
        }
        else {
            colorForPin = StyleController.greenQuakeColor
        }
        
        annotationView.pinTintColor = colorForPin
        
        return annotationView
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
