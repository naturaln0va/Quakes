
import UIKit
import MapKit
import CoreLocation
import SafariServices

class DetailViewController: UIViewController {

    @IBOutlet var nameHeaderLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    fileprivate lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.isUserInteractionEnabled = false
        map.delegate = self
        return map
    }()
    
    fileprivate lazy var openInMapButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("View on Map", for: UIControlState())
        button.setTitleColor(UIColor.black, for: UIControlState())
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightMedium)
        button.addTarget(self, action: #selector(DetailViewController.openInMapButtonPressed), for: .touchUpInside)
        button.backgroundColor = StyleController.backgroundColor
        button.sizeToFit()
        return button
    }()
    
    fileprivate lazy var feltButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("I Felt This", for: UIControlState())
        button.setTitleColor(UIColor.black, for: UIControlState())
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightMedium)
        button.addTarget(self, action: #selector(DetailViewController.feltButtonPressed), for: .touchUpInside)
        button.backgroundColor = StyleController.backgroundColor
        button.sizeToFit()
        return button
    }()
    
    fileprivate lazy var titleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "WW"))
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowRadius = 1.75
        imageView.layer.shadowOffset = CGSize.zero
        return imageView
    }()
    
    let geocoder = CLGeocoder()
    let titleIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let mainQueue = OperationQueue.main
    let manager = CLLocationManager()
    
    var quakeToDisplay: Quake!
    var parsedNearbyCities: [ParsedNearbyCity]? {
        didSet {
            if let _ = parsedNearbyCities {
                tableView.reloadData()
            }
        }
    }
    var lastUserLocation: CLLocation?
    var distanceFromQuake: Double = 0.0
    
    init(quake: Quake) {
        super.init(nibName: String(describing: DetailViewController.self), bundle: nil)
        self.quakeToDisplay = quake
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TelemetryController.sharedController.logQuakeDetailViewed(quakeToDisplay.weblink ?? "Unknown URL")
        
        if let nearbyCities = quakeToDisplay.nearbyCities {
            parsedNearbyCities = nearbyCities
        }
        else if let url = URL(string: quakeToDisplay.detailURL), quakeToDisplay.nearbyCities == nil {
            NetworkUtility.networkOperationStarted()
            
            let downloadDetailOperation = DownloadDetailOperation(url: url)
            let downloadNearbyCitiesOperation = DownloadNearbyCitiesOperation()
                            
            downloadNearbyCitiesOperation.completionBlock = {
                NetworkUtility.networkOperationFinished()
                if let cities = downloadNearbyCitiesOperation.downloadedCities, cities.count > 0 {
                    PersistentController.sharedController.updateQuakeWithID(self.quakeToDisplay.identifier, withNearbyCities: cities, withCountry: nil)
                    
                    DispatchQueue.main.async {
                        self.parsedNearbyCities = cities
                    }
                }
            }
            
            downloadNearbyCitiesOperation.addDependency(downloadDetailOperation)
            
            mainQueue.maxConcurrentOperationCount = 1
            mainQueue.qualityOfService = .userInitiated
            mainQueue.addOperations([downloadDetailOperation, downloadNearbyCitiesOperation], waitUntilFinished: false)
        }
        
        title = "Detail"
        if let countryCode = quakeToDisplay.countryCode {
            titleImageView.image = UIImage(named: countryCode) ?? UIImage(named: "WW")
            navigationItem.titleView = titleImageView
        }
        else {
            navigationItem.titleView = titleIndicatorView
            titleIndicatorView.startAnimating()
        }
        
        nameHeaderLabel.text = quakeToDisplay.name.components(separatedBy: " of ").last!
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(DetailViewController.shareButtonPressed))
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
        
        mapView.removeAnnotation(quakeToDisplay)
        mapView.addAnnotation(quakeToDisplay)
        mapView.region = MKCoordinateRegion(
            center: quakeToDisplay.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(red: 0.933,  green: 0.933,  blue: 0.933, alpha: 1.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if quakeToDisplay.countryCode == nil {
            var stringToSearch = ""
            if let lastLocationName = quakeToDisplay.name.components(separatedBy: " of ").last?.components(separatedBy: ", ").last {
                stringToSearch = lastLocationName
            }
            else if let wholeLocationName = quakeToDisplay.name.components(separatedBy: " of ").last {
                stringToSearch = wholeLocationName
            }
            
            NetworkUtility.networkOperationStarted()
            geocoder.geocodeAddressString(stringToSearch) { marks, error -> Void in
                NetworkUtility.networkOperationFinished()
                
                DispatchQueue.main.async {
                    if let mark = marks?.first, let code = mark.isoCountryCode, error == nil {
                        PersistentController.sharedController.updateQuakeWithID(self.quakeToDisplay.identifier, withNearbyCities: nil, withCountry: code)
                        self.titleImageView.image = UIImage(named: code) ?? UIImage(named: "WW")
                        self.navigationItem.titleView = self.titleImageView
                    }
                    else {
                        self.navigationItem.titleView = self.titleImageView
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.set(bottomDividerLineHidden: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.set(bottomDividerLineHidden: false)
        
        if titleIndicatorView.superview != nil {
            titleIndicatorView.removeFromSuperview()
            navigationItem.titleView = nil
        }
        
        if geocoder.isGeocoding {
            geocoder.cancelGeocode()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if tableView.tableHeaderView == nil {
            let headerContainerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 275))
            headerContainerView.translatesAutoresizingMaskIntoConstraints = true
            headerContainerView.clipsToBounds = true
            
            mapView.translatesAutoresizingMaskIntoConstraints = false
            openInMapButton.translatesAutoresizingMaskIntoConstraints = false
            feltButton.translatesAutoresizingMaskIntoConstraints = false
            
            headerContainerView.addSubview(mapView)
            headerContainerView.addSubview(openInMapButton)
            headerContainerView.addSubview(feltButton)
            
            let views = ["map": mapView, "open": openInMapButton, "feels": feltButton] as [String : Any]
            headerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[map]|", options: [], metrics: nil, views: views))
            headerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[open][feels(==open)]|", options: [], metrics: ["size": view.frame.width / 2], views: views))
            headerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[map][open(==44)]|", options: [], metrics: nil, views: views))
            headerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[map][feels(==44)]|", options: [], metrics: nil, views: views))
            openInMapButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
            
            tableView.tableHeaderView = headerContainerView
        }
    }
    
    // MARK: - Actions
    internal func openInMapButtonPressed() {
        if let rootVC = navigationController?.viewControllers.first as? ListViewController {
            _ = navigationController?.popViewController(animated: true)
            
            let mapVC = MapViewController(centeredOnLocation: quakeToDisplay.coordinate)
            mapVC.delegate = rootVC
            
            navigationController?.pushViewController(mapVC, animated: true)
        }
    }
    
    internal func feltButtonPressed() {
        if let urlString = quakeToDisplay.weblink, let url = URL(string: "\(urlString)#tellus") {
            let safariVC = SFSafariViewController(url: url)
            
            if #available(iOS 10.0, *) {
                safariVC.preferredControlTintColor = quakeToDisplay.severityColor
            }
            else {
                safariVC.view.tintColor = quakeToDisplay.severityColor
            }
            
            DispatchQueue.main.async {
                self.present(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    internal func shareButtonPressed() {
        guard let urlString = quakeToDisplay.weblink, let url = URL(string: urlString) else { return }
        let options = MKMapSnapshotOptions()
        options.region = MKCoordinateRegion(center: quakeToDisplay.coordinate, span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2))
        options.size = mapView.frame.size
        options.scale = UIScreen.main.scale
        options.mapType = .hybrid
        
        MKMapSnapshotter(options: options).start (completionHandler: { snapshot, error in
            let prompt = "A \(Quake.magnitudeFormatter.string(from: NSNumber(value: self.quakeToDisplay.magnitude))!) magnitude earthquake happened \(self.quakeToDisplay.timestamp.relativeString()) ago near \(self.quakeToDisplay.name.components(separatedBy: " of ").last!)."
            var items: [Any] = [prompt, url, self.quakeToDisplay.location]
            
            if let shot = snapshot, error == nil {
                let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let image = shot.image
                
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                image.draw(at: CGPoint.zero)
                
                let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
                var point = shot.point(for: self.quakeToDisplay.coordinate)
                if visibleRect.contains(point) {
                    point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                    point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                    pin.image?.draw(at: point)
                }
                
                if let compositeImage = UIGraphicsGetImageFromCurrentImageContext() {
                    items.append(compositeImage)
                }
                UIGraphicsEndImageContext()
            }
            
            DispatchQueue.main.async {
                self.present(UIActivityViewController(
                    activityItems: items,
                    applicationActivities: nil),
                    animated: true,
                    completion: { _ in
                        TelemetryController.sharedController.logQuakeShare()
                    }
                )
            }
        })
    }
    
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "quakeInfoCell")
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Magnitude"
                cell.detailTextLabel?.text = Quake.magnitudeFormatter.string(from: NSNumber(value: quakeToDisplay.magnitude))
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Depth"
                Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
                cell.detailTextLabel?.text = Quake.distanceFormatter.string(fromDistance: quakeToDisplay.depth)
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
                cell.detailTextLabel?.text = Quake.timestampFormatter.string(from: quakeToDisplay.timestamp)
            }
                
            if quakeToDisplay.felt > 0 && distanceFromQuake > 0 {
                if indexPath.row == 5 {
                    cell.textLabel?.text = "Felt By"
                    cell.detailTextLabel?.text = "\(Int(quakeToDisplay.felt)) people"
                }
                else if indexPath.row == 6 {
                    Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
                    cell.textLabel?.text = "Distance"
                    cell.detailTextLabel?.text = Quake.distanceFormatter.string(fromDistance: distanceFromQuake)
                }
            }
            else if quakeToDisplay.felt > 0 && distanceFromQuake == 0 {
                if indexPath.row == 5 {
                    cell.textLabel?.text = "Felt By"
                    cell.detailTextLabel?.text = "\(Int(quakeToDisplay.felt)) people"
                }
            }
            else if quakeToDisplay.felt == 0 && distanceFromQuake > 0 {
                if indexPath.row == 5 {
                    Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
                    cell.textLabel?.text = "Distance"
                    cell.detailTextLabel?.text = Quake.distanceFormatter.string(fromDistance: distanceFromQuake)
                }
            }
        }
        else if indexPath.section == 1 {
            if let cities = parsedNearbyCities {
                cell.textLabel?.text = cities[indexPath.row].cityName
                cell.accessoryType = .disclosureIndicator
            }
            else {
                let websiteLabel = UILabel()
                websiteLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightMedium)
                websiteLabel.translatesAutoresizingMaskIntoConstraints = false
                websiteLabel.textColor = quakeToDisplay.severityColor
                websiteLabel.text = "Open in USGS"
                websiteLabel.textAlignment = .center
                
                cell.translatesAutoresizingMaskIntoConstraints = true
                cell.addSubview(websiteLabel)
                
                let views = ["label": websiteLabel]
                cell.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: [], metrics: nil, views: views))
                cell.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|", options: [], metrics: nil, views: views))
            }
        }
        else {
            let websiteLabel = UILabel()
            websiteLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightMedium)
            websiteLabel.translatesAutoresizingMaskIntoConstraints = false
            websiteLabel.textColor = quakeToDisplay.severityColor
            websiteLabel.text = "Open in USGS"
            websiteLabel.textAlignment = .center
            
            cell.translatesAutoresizingMaskIntoConstraints = true
            cell.addSubview(websiteLabel)
            
            let views = ["label": websiteLabel]
            cell.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: [], metrics: nil, views: views))
            cell.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|", options: [], metrics: nil, views: views))
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return parsedNearbyCities != nil ? "Nearby Cities" : nil
        }
        else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard NetworkUtility.internetReachable() else {
            return
        }
        
        if let urlString = quakeToDisplay.weblink, let url = URL(string: urlString), parsedNearbyCities != nil ? indexPath.section == 2 : indexPath.section == 1 && indexPath.row == 0 {
            let safariVC = SFSafariViewController(url: url)
            
            if #available(iOS 10.0, *) {
                safariVC.preferredControlTintColor = quakeToDisplay.severityColor
            }
            else {
                safariVC.view.tintColor = quakeToDisplay.severityColor
            }
            
            DispatchQueue.main.async {
                self.present(safariVC, animated: true, completion: { _ in
                    TelemetryController.sharedController.logQuakeOpenedInBrowser()
                })
            }
        }
        else if let citiesToDisplay = parsedNearbyCities, indexPath.section == 1 && parsedNearbyCities != nil {
            TelemetryController.sharedController.logQuakeCitiesViewed()
            let selectedCity = citiesToDisplay[indexPath.row]
            let sortedCities = citiesToDisplay.sorted(by: { $0.0.cityName == selectedCity.cityName })
            navigationController?.pushViewController(MapViewController(quakeToDisplay: quakeToDisplay, nearbyCities: sortedCities), animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    // MARK: - UITableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return parsedNearbyCities != nil ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            var offset = 0
            if quakeToDisplay.felt == 0 {
                offset += 1
            }
            if distanceFromQuake == 0 {
                offset += 1
            }
            return 7 - offset
        }
        else if section == 1 {
            return parsedNearbyCities != nil ? parsedNearbyCities!.count : 1
        }
        else {
            return 1
        }
    }
    
}

extension DetailViewController: CLLocationManagerDelegate
{
    
    // MARK: - CLLocationManager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}

extension DetailViewController: MKMapViewDelegate
{
    
    // MARK: - MKMapView Delegate
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        guard let userLocation = userLocation.location, userLocation.horizontalAccuracy > 0 else {
            return
        }
        
        if let lastLocation = lastUserLocation, lastLocation.distance(from: userLocation) > 25.0 {
            return
        }
        
        distanceFromQuake = userLocation.distance(from: quakeToDisplay.location)
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        
        if userLocation.distance(from: quakeToDisplay.location) > (1000 * 900) {
            return
        }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
        
        lastUserLocation = userLocation
    }
    
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
            
            annotationView.pinTintColor = quakeToDisplay.severityColor
            
            return annotationView
        }
    }
    
}
