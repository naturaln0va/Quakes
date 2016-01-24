
import UIKit
import MapKit
import CoreLocation
import SafariServices

class DetailViewController: UITableViewController {

    private lazy var mapView: MKMapView = {
        let map = MKMapView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.mainScreen().bounds.width, height: 220.0))
        map.userInteractionEnabled = false
        map.delegate = self
        return map
    }()
    
    let mainQueue = NSOperationQueue.mainQueue()
    let manager = CLLocationManager()
    var quakeToDisplay: Quake!
    var parsedNearbyCities: [ParsedNearbyCity]?
    var lastUserLocation: CLLocation?
    var distanceStringForCell: String?
    var hasNearbyCityInfo: Bool = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    init(quake: Quake) {
        super.init(style: .Grouped)
        self.quakeToDisplay = quake
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nearbyCities = quakeToDisplay.nearbyCities {
            self.parsedNearbyCities = nearbyCities
            self.hasNearbyCityInfo = true
        }
        else if let url = NSURL(string: quakeToDisplay.detailURL) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let downloadDetailOperation = DownloadDetailOperation(url: url)
            let downloadNearbyCitiesOperation = DownloadNearbyCitiesOperation()
            
            downloadNearbyCitiesOperation.completionBlock = {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let cities = downloadNearbyCitiesOperation.downloadedCities where cities.count > 0 {
                    PersistentController.sharedController.updateQuakeWithID(self.quakeToDisplay.identifier, withNearbyCities: cities)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.parsedNearbyCities = cities
                        self.hasNearbyCityInfo = true
                    }
                }
            }
            
            downloadDetailOperation |> downloadNearbyCitiesOperation
            
            mainQueue.maxConcurrentOperationCount = 1
            mainQueue.qualityOfService = .UserInitiated
            mainQueue.addOperations([downloadDetailOperation, downloadNearbyCitiesOperation], waitUntilFinished: false)
        }
        
        title = quakeToDisplay.name.componentsSeparatedByString(" of ").last!
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareButtonPressed")
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
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
        let options = MKMapSnapshotOptions()
        options.region = MKCoordinateRegion(center: quakeToDisplay.coordinate, span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2))
        options.size = mapView.frame.size
        options.scale = UIScreen.mainScreen().scale
        options.mapType = .Hybrid
        
        MKMapSnapshotter(options: options).startWithCompletionHandler { snapshot, error in
            
            let prompt = "A \(Quake.magnitudeFormatter.stringFromNumber(self.quakeToDisplay.magnitude)!) magnitude earthquake happened \(relativeStringForDate(self.quakeToDisplay.timestamp)) ago near \(self.quakeToDisplay.name.componentsSeparatedByString(" of ").last!)."
            var items = [prompt, url, self.quakeToDisplay.location]
            
            if let shot = snapshot where error == nil {
                let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let image = shot.image
                
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                image.drawAtPoint(CGPoint.zero)
                
                let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
                var point = shot.pointForCoordinate(self.quakeToDisplay.coordinate)
                if visibleRect.contains(point) {
                    point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                    point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                    pin.image?.drawAtPoint(point)
                }
                
                let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                items.append(compositeImage)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(UIActivityViewController(
                    activityItems: items,
                    applicationActivities: nil),
                    animated: true,
                    completion: nil
                )
            }
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
            if hasNearbyCityInfo {
                cell.textLabel?.text = parsedNearbyCities![indexPath.row].cityName
                cell.accessoryType = .DisclosureIndicator
            }
            else {
                cell.textLabel?.text = "Open in USGS.gov"
                cell.accessoryType = .DisclosureIndicator
            }
        }
        else {
            cell.textLabel?.text = "Open in USGS.gov"
            cell.accessoryType = .DisclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       if section == 1 {
            return hasNearbyCityInfo ? "Nearby Cities" : nil
        }
        else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if let url = NSURL(string: quakeToDisplay.weblink) where hasNearbyCityInfo ? indexPath.section == 2 : indexPath.section == 1 && indexPath.row == 0 {
            let safariVC = SFSafariViewController(URL: url)
            safariVC.view.tintColor = StyleController.darkerMainAppColor
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(safariVC, animated: true, completion: nil)
            }
        }
        else if let citiesToDisplay = parsedNearbyCities where indexPath.section == 1 && hasNearbyCityInfo {
            navigationController?.pushViewController(MapViewController(quakeToDisplay: quakeToDisplay, nearbyCities: citiesToDisplay), animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    // MARK: - UITableView DataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return hasNearbyCityInfo ? 3 : 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 6
        }
        else if section == 1 {
            return hasNearbyCityInfo ? parsedNearbyCities!.count : 1
        }
        else {
            return 1
        }
    }

}

extension DetailViewController: CLLocationManagerDelegate
{
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}

extension DetailViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        guard let userLocation = userLocation.location where userLocation.horizontalAccuracy > 0 else {
            return
        }
        
        if let lastLocation = lastUserLocation where lastLocation.distanceFromLocation(userLocation) > 25.0 {
            return
        }
        
        distanceStringForCell = Quake.distanceFormatter.stringFromMeters(userLocation.distanceFromLocation(quakeToDisplay.location))
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 5, inSection: 0)], withRowAnimation: .Automatic)
        
        if userLocation.distanceFromLocation(quakeToDisplay.location) > (1000 * 900) {
            return
        }
        
        let userMapPoint = MKMapPointForCoordinate(userLocation.coordinate)
        let quakeMapPoint = MKMapPointForCoordinate(quakeToDisplay.coordinate)
        
        let mapRect = MKMapRectMake(min(userMapPoint.x, quakeMapPoint.x), min(userMapPoint.y, quakeMapPoint.y), abs(userMapPoint.x - quakeMapPoint.x), abs(userMapPoint.y - quakeMapPoint.y))
        mapView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 55, left: 27, bottom: 55, right: 27), animated: true)
        
        lastUserLocation = userLocation
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
