
import UIKit
import MapKit
import SafariServices

enum PeekableActionType {
    case share
    case felt
    case open
}

protocol PeekableDetailViewControllerDelegate {
    func peekableViewController(viewController: PeekableDetailViewController, didSelect actionType: PeekableActionType)
}

class PeekableDetailViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    
    let quakeToDisplay: Quake
    var delegate: PeekableDetailViewControllerDelegate?
    
    var lastUserLocation: CLLocation?
    var distanceFromQuake: Double = 0.0 {
        didSet {
            if distanceFromQuake > 0 {
                distanceLabel.text = Quake.distanceFormatter.string(fromDistance: distanceFromQuake)
            }
        }
    }
    
    init(quake: Quake) {
        quakeToDisplay = quake
        super.init(nibName: String(describing: PeekableDetailViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        var items = [UIPreviewActionItem]()
        
        items.append(UIPreviewAction(title: "Share", style: .default, handler: { action, viewController in
            self.delegate?.peekableViewController(viewController: self, didSelect: .share)
        }))
        items.append(UIPreviewAction(title: "I Felt This", style: .default, handler: { action, viewController in
            self.delegate?.peekableViewController(viewController: self, didSelect: .felt)
        }))
        items.append(UIPreviewAction(title: "Open in USGS", style: .default, handler: { action, viewController in
            self.delegate?.peekableViewController(viewController: self, didSelect: .open)
        }))
        
        return items
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.addAnnotation(quakeToDisplay)
        mapView.region = MKCoordinateRegion(
            center: quakeToDisplay.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        
        if LocationHelper.isLocationEnabled {
            mapView.showsUserLocation = true
        }
        
        headerLabel.text = "\(Quake.magnitudeFormatter.string(from: NSNumber(value: quakeToDisplay.magnitude))!) \(quakeToDisplay.name.components(separatedBy: " of ").last!)"
        dateLabel.text = Quake.timestampFormatter.string(from: quakeToDisplay.timestamp)
        distanceLabel.text = ""
    }
    
}

extension PeekableDetailViewController: MKMapViewDelegate {
    
    // MARK: - MKMapView Delegate
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let userLocation = userLocation.location, userLocation.horizontalAccuracy > 0 else {
            return
        }
        
        if let lastLocation = lastUserLocation, lastLocation.distance(from: userLocation) > 25.0 {
            return
        }
        
        distanceFromQuake = userLocation.distance(from: quakeToDisplay.location)
        
        if userLocation.distance(from: quakeToDisplay.location) > (1000 * 900) {
            return
        }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
        
        lastUserLocation = userLocation
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Quake else {
            return nil
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Quake") as? MKPinAnnotationView {
            return annotationView
        }
        else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Quake")
            annotationView.isEnabled = true
            annotationView.animatesDrop = true
            
            var colorForPin = StyleController.greenQuakeColor
            if quakeToDisplay.magnitude >= 4.0 {
                colorForPin = StyleController.redQuakeColor
            }
            else if quakeToDisplay.magnitude >= 3.0 {
                colorForPin = StyleController.orangeQuakeColor
            }
            else {
                colorForPin = StyleController.greenQuakeColor
            }
            
            annotationView.pinTintColor = colorForPin
            
            return annotationView
        }
    }
    
}
