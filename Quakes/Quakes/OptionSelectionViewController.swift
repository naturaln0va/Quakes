
import UIKit
import CoreLocation

enum LocationOption: String {
    case Nearby
    case World
    case Major
}

protocol OptionSelectionViewControllerDelegate {
    func optionSelectionViewControllerDidSelectPlace(placemark: CLPlacemark)
    func optionSelectionViewControllerDidSelectOption(option: LocationOption)
}

class OptionSelectionViewController: UITableViewController {

    var delegate: OptionSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Options"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "dismiss")
        
        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(red: 0.933,  green: 0.933,  blue: 0.933, alpha: 1.0)
        
        let identifer = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
        
        let appVersionAndBuildStringLabel = UILabel()
        appVersionAndBuildStringLabel.textColor = UIColor(white: 0.0, alpha: 0.5)
        appVersionAndBuildStringLabel.text = "Quakes v\(identifer).\(build)"
        appVersionAndBuildStringLabel.textAlignment = .Center
        appVersionAndBuildStringLabel.sizeToFit()
        appVersionAndBuildStringLabel.center = CGPoint(x: view.center.x, y: CGRectGetHeight(view.bounds) - (CGRectGetHeight(appVersionAndBuildStringLabel.frame) * 3.2))
        tableView.addSubview(appVersionAndBuildStringLabel)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UITableView Delegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "quakeInfoCell")
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Nearby"
                switch CLLocationManager.authorizationStatus() {
                case .AuthorizedWhenInUse:
                    if CLLocationManager.locationServicesEnabled() {
                        cell.detailTextLabel?.text = "Nearby earthquakes"
                    }
                    else {
                        cell.detailTextLabel?.text = "Location services are turned off"
                    }
                    break
                default:
                    cell.detailTextLabel?.text = "Location access is denied"
                    break
                }
                cell.accessoryType = SettingsController.sharedContoller.lastLocationOption == LocationOption.Nearby.rawValue ? .Checkmark : .None
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Worldwide"
                cell.detailTextLabel?.text = "Earthquakes around the world"
                cell.accessoryType = SettingsController.sharedContoller.lastLocationOption == LocationOption.World.rawValue ? .Checkmark : .None
            }
            else if indexPath.row == 2 {
                cell.textLabel?.text = "Significant"
                cell.detailTextLabel?.text = "Major earthquakes"
                cell.accessoryType = SettingsController.sharedContoller.lastLocationOption == LocationOption.Major.rawValue ? .Checkmark : .None
            }
            
            cell.tintColor = StyleController.mainAppColor
        }
        else if indexPath.section == 1 {
            cell.textLabel?.text = "Enter a location"
            cell.accessoryType = .DisclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                var errorMessage = ""
                switch CLLocationManager.authorizationStatus() {
                case .AuthorizedWhenInUse:
                    if CLLocationManager.locationServicesEnabled() {
                        delegate?.optionSelectionViewControllerDidSelectOption(.Nearby)
                        dismiss()
                    }
                    else {
                        errorMessage = "Location services are turned off"
                    }
                    break
                default:
                    errorMessage = "Location access is denied"
                    break
                }
                
                let alertView = UIAlertController(title: "Location Error", message: errorMessage, preferredStyle: .Alert)
                
                alertView.addAction(UIAlertAction(title: "Open Settings", style: .Default, handler: { action in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
                
                alertView.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                
                presentViewController(alertView, animated: true, completion: nil)
            }
            else if indexPath.row == 1 {
                delegate?.optionSelectionViewControllerDidSelectOption(.World)
                dismiss()
            }
            else if indexPath.row == 2 {
                delegate?.optionSelectionViewControllerDidSelectOption(.Major)
                dismiss()
            }
        }
        else if indexPath.section == 1 && indexPath.row == 0 {
            if let delegate = delegate {
                navigationController?.pushViewController(LocationFinderViewController(delegate: delegate), animated: true)
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 1 ? "The most recent earthquakes are shown for each option." : nil
    }
    
    // MARK: - UITableView DataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 1
    }
    
}
