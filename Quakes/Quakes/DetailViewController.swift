
import UIKit
import MapKit
import CoreLocation
import SafariServices

class DetailViewController: UITableViewController {

    private lazy var mapView: MKMapView = {
        let map = MKMapView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.mainScreen().bounds.width, height: 220.0))
        map.showsUserLocation = true
        map.userInteractionEnabled = false
        return map
    }()
    
    var quakeToDisplay: Quake!
    var lastUserLocation: CLLocation?
    var distanceStringForCell: String?
    
    init(quake: Quake) {
        super.init(style: .Grouped)
        self.quakeToDisplay = quake
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = quakeToDisplay.name.componentsSeparatedByString(" of ").last!
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareButtonPressed")
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.delegate = self
        }
        
        mapView.removeAnnotation(quakeToDisplay)
        mapView.addAnnotation(quakeToDisplay)
        tableView.tableHeaderView = mapView
        
        let regionForQuake = MKCoordinateRegion(center: quakeToDisplay.coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        mapView.setRegion(mapView.regionThatFits(regionForQuake), animated: false)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(red: 0.933,  green: 0.933,  blue: 0.933, alpha: 1.0)
    }
    
    internal func shareButtonPressed() {
        guard let url = NSURL(string: quakeToDisplay.weblink) else { return }
        
        let prompt = "A \(Quake.magnitudeFormatter.stringFromNumber(quakeToDisplay.magnitude)!) magnitude earthquake happened \(relativeStringForDate(quakeToDisplay.timestamp)) ago near \(quakeToDisplay.name.componentsSeparatedByString(" of ").last!)."
        let items = [prompt, url, quakeToDisplay.location]
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(UIActivityViewController(
                activityItems: items,
                applicationActivities: nil),
                animated: true,
                completion: nil
            )
        }
    }
    
    // MARK: - UITableView Delegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "quakeInfoCell")
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Magnitude"
                cell.detailTextLabel?.text = Quake.magnitudeFormatter.stringFromNumber(quakeToDisplay.magnitude)
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Depth"
                cell.detailTextLabel?.text = Quake.depthFormatter.stringFromMeters(quakeToDisplay.depth)
            }
            else if indexPath.row == 2 {
                cell.textLabel?.text = "Location"
                cell.detailTextLabel?.text = quakeToDisplay.name
            }
            else if indexPath.row == 3 {
                cell.textLabel?.text = "Coordinate"
                cell.detailTextLabel?.text = quakeToDisplay.coordinate.formatedString()
            }
            else if indexPath.row == 4 {
                cell.textLabel?.text = "Date & Time"
                cell.detailTextLabel?.text = Quake.timestampFormatter.stringFromDate(quakeToDisplay.timestamp)
            }
            else if indexPath.row == 5 {
                cell.textLabel?.text = "Distance"
                cell.detailTextLabel?.text = distanceStringForCell == nil ? "N/A" : distanceStringForCell!
            }
        }
        else if indexPath.section == 1 {
            cell.textLabel?.text = "Open in USGS.gov"
            cell.accessoryType = .DisclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if let url = NSURL(string: quakeToDisplay.weblink) where indexPath.section == 1 && indexPath.row == 0 {
            let safariVC = SFSafariViewController(URL: url)
            safariVC.view.tintColor = StyleController.mainAppColor
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    // MARK: - UITableView DataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 6 : 1
    }

}

extension DetailViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        if let lastLocation = lastUserLocation {
            guard let currentUserLocation = userLocation.location
                where lastLocation.distanceFromLocation(currentUserLocation) > 25.0 else {
                    return
            }
            
            if currentUserLocation.distanceFromLocation(quakeToDisplay.location) > 2500 {
                let indexPathToUpdate = NSIndexPath(forRow: 5, inSection: 0)
                if let userLocation = userLocation.location {
                    distanceStringForCell = Quake.distanceFormatter.stringFromMeters(userLocation.distanceFromLocation(quakeToDisplay.location))
                    tableView.reloadRowsAtIndexPaths([indexPathToUpdate], withRowAnimation: .Automatic)
                }
                return
            }
        }
        
        let center = CLLocationCoordinate2D(
            latitude: userLocation.coordinate.latitude - (userLocation.coordinate.latitude - quakeToDisplay.coordinate.latitude) / 2,
            longitude: userLocation.coordinate.longitude - (userLocation.coordinate.longitude - quakeToDisplay.coordinate.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(1 / 55, abs(userLocation.coordinate.latitude - quakeToDisplay.coordinate.latitude) * 2.5),
            longitudeDelta: max(1 / 55, abs(userLocation.coordinate.longitude - quakeToDisplay.coordinate.longitude) * 2.5)
        )
        
        if CLLocationCoordinate2DIsValid(center) {
            let region = MKCoordinateRegionMake(center, span)
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
        }
        
        lastUserLocation = userLocation.location
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard annotation is Quake else {
            return nil
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("Quake") as? MKPinAnnotationView {
            return annotationView
        }
        else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Quake")
            annotationView.enabled = true
            annotationView.animatesDrop = false
            
            var colorForPin = UIColor(red: 0.180,  green: 0.533,  blue: 0.180, alpha: 1.0)
            if quakeToDisplay.magnitude >= 4.0 {
                colorForPin = UIColor(red: 0.667,  green: 0.224,  blue: 0.224, alpha: 1.0)
            }
            else if quakeToDisplay.magnitude >= 3.0 {
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
