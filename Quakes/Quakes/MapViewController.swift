
import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController
{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locateButton: UIButton!
    
    var quakesToDisplay: [Quake]!
    var shouldContinueUpdatingUserLocation = true
    
    init(quakes: [Quake]) {
        quakesToDisplay = quakes
        super.init(nibName: String(MapViewController), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("ann: \(quakesToDisplay)")
        
        mapView.showsCompass = true
        mapView.delegate = self
    }
    
    func refreshMapWithQuakesWithUserLocation() {
        mapView.removeAnnotations(mapView.annotations)
        let deltaDegreeSpan: Double = 1 / 55.5
        
        if SettingsController.sharedContoller.lastLocationOption == LocationOption.Nearby.rawValue {
            var locations = quakesToDisplay.map { $0.location }
            
            if let userLocation = mapView.userLocation.location {
                locations.append(userLocation)
            }
            
            var center = CLLocationCoordinate2D()
            var span = MKCoordinateSpan()
            if locations.count == 1 {
                center = CLLocationCoordinate2D(
                    latitude: mapView.userLocation.location!.coordinate.latitude,
                    longitude: mapView.userLocation.location!.coordinate.longitude
                )
                span = MKCoordinateSpan(
                    latitudeDelta: deltaDegreeSpan,
                    longitudeDelta: deltaDegreeSpan
                )
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
                
                center = CLLocationCoordinate2D(
                    latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
                    longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2
                )
                span = MKCoordinateSpan(
                    latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.35,
                    longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * 1.35
                )
            }
            
            let fittedRegion = mapView.regionThatFits(MKCoordinateRegionMake(center, span))
            
            mapView.setRegion(fittedRegion, animated: false)
        }
        else {
            var regionForQuake = MKCoordinateRegion()
            if let latestQuake = quakesToDisplay.sort({ $0.timestamp.timeIntervalSince1970 > $1.timestamp.timeIntervalSince1970 }).first {
                regionForQuake = MKCoordinateRegion(
                    center: latestQuake.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2)
                )
            }
            else {
                if let userLocation = mapView.userLocation.location {
                    regionForQuake = MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                    )
                }
            }
            mapView.setRegion(mapView.regionThatFits(regionForQuake), animated: false)
        }
        
        mapView.addAnnotations(quakesToDisplay)
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldContinueUpdatingUserLocation else { return }
        
        if let _ = userLocation.location {
            refreshMapWithQuakesWithUserLocation()
            shouldContinueUpdatingUserLocation = false
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard let annotation = annotation as? Quake else {
            return nil
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("Quake") as? MKPinAnnotationView {
            return annotationView
        }
        else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Quake")
            annotationView.enabled = true
            annotationView.animatesDrop = false
            annotationView.canShowCallout = true
            
            var colorForPin = UIColor(red: 0.180,  green: 0.533,  blue: 0.180, alpha: 1.0)
            if annotation.magnitude >= 4.0 {
                colorForPin = UIColor(red: 0.667,  green: 0.224,  blue: 0.224, alpha: 1.0)
            }
            else if annotation.magnitude >= 3.0 {
                colorForPin = UIColor(red: 0.799,  green: 0.486,  blue: 0.163, alpha: 1.0)
            }
            else {
                colorForPin = UIColor(red: 0.180,  green: 0.533,  blue: 0.180, alpha: 1.0)
            }
            
            annotationView.pinTintColor = colorForPin
            
            return annotationView
        }
    }
    
}
