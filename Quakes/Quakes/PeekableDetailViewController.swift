
import UIKit
import MapKit

class PeekableDetailViewController: UIViewController
{

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var magnitudeColorView: SeverityView!
    
    let quakeToDisplay: Quake
    
    init(quake: Quake) {
        quakeToDisplay = quake
        super.init(nibName: String(describing: PeekableDetailViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.addAnnotation(quakeToDisplay)
        mapView.region = MKCoordinateRegion(
            center: quakeToDisplay.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        
        headerLabel.text = "\(Quake.magnitudeFormatter.string(from: NSNumber(value: quakeToDisplay.magnitude))!) \(quakeToDisplay.name.components(separatedBy: " of ").last!)"
    }
    
}

extension PeekableDetailViewController: MKMapViewDelegate
{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
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
