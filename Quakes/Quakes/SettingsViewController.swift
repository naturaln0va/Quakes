
import UIKit
import MapKit
import MessageUI
import SafariServices

class SettingsViewController: UITableViewController
{
    
    enum UserSectionRows: Int {
        case LimitRow
        case RadiusRow
        case UnitRow
        case TotalRows
    }
    
    enum GeneralSectionRows: Int {
        case RemoveAdsRow
        case RateRow
        case ContactRow
        case TotalRows
    }
    
    enum ExtraSectionRows: Int {
        case PrivacyRow
        case PermissionRow
        case TotalRows
    }
    
    enum TableSections: Int {
        case UserSection
        case GeneralSection
        case ExtraSection
        case TotalSections
    }
    
    enum SwitchTag: Int {
        case Unit
    }
    
    private lazy var formatter: MKDistanceFormatter = {
        let distFormatter = MKDistanceFormatter()
        distFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
        return distFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(SettingsViewController.doneButtonPressed))
    }
    
    // MARK: - Actions
    func doneButtonPressed()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func switchWasToggled(sender: UISwitch)
    {
        switch sender.tag {
            
        case SwitchTag.Unit.rawValue:
            TelemetryController.sharedController.logUnitStyleToggled()
            SettingsController.sharedController.isUnitStyleImperial = !sender.on
            formatter.units = !sender.on ? .Imperial : .Metric
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .None)
            break
            
        default:
            break
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return TableSections.TotalSections.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == TableSections.GeneralSection.rawValue {
            return GeneralSectionRows.TotalRows.rawValue
        }
        else if section == TableSections.UserSection.rawValue {
            return UserSectionRows.TotalRows.rawValue
        }
        else if section == TableSections.ExtraSection.rawValue {
            return ExtraSectionRows.TotalRows.rawValue
        }
        else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == TableSections.TotalSections.rawValue - 1 ? "Quakes v" + UIDevice.currentDevice().appVersionAndBuildString : nil
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "defaultCell")
        
        if indexPath.section == TableSections.UserSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.LimitRow.rawValue:
                cell.textLabel?.text = "Fetch Size"
                cell.detailTextLabel?.text = SettingsController.sharedController.fetchLimit.displayString()
                cell.accessoryType = .DisclosureIndicator
                break
                
            case UserSectionRows.RadiusRow.rawValue:
                cell.textLabel?.text = "Nearby Radius"
                cell.detailTextLabel?.text = formatter.stringFromDistance(CLLocationDistance(SettingsController.sharedController.searchRadius.rawValue * 1000))
                cell.accessoryType = .DisclosureIndicator
                break
                
            case UserSectionRows.UnitRow.rawValue:
                cell.textLabel?.text = "Metric Unit Style"
                
                let unitSwitch = UISwitch()
                unitSwitch.tag = SwitchTag.Unit.rawValue
                unitSwitch.on = !SettingsController.sharedController.isUnitStyleImperial
                unitSwitch.addTarget(
                    self,
                    action: #selector(SettingsViewController.switchWasToggled(_:)),
                    forControlEvents: .ValueChanged
                )
                
                cell.accessoryView = unitSwitch
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.GeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                cell.textLabel?.text = "Rate on the App Store"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case GeneralSectionRows.RemoveAdsRow.rawValue:
                cell.textLabel?.text = "Support the App"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case GeneralSectionRows.ContactRow.rawValue:
                cell.textLabel?.text = "Contact the Developer"
                cell.accessoryType = .DisclosureIndicator
                cell.userInteractionEnabled = MFMailComposeViewController.canSendMail()
                cell.textLabel?.enabled = MFMailComposeViewController.canSendMail()
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.ExtraSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                cell.textLabel?.text = "Privacy"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case GeneralSectionRows.RemoveAdsRow.rawValue:
                cell.textLabel?.text = "Permissions"
                cell.accessoryType = .DisclosureIndicator
                break
                
            default:
                break
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == TableSections.GeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/us/app/quakes-earthquake-utility/id1071904740?ls=1&mt=8")!)
                break
                
            case GeneralSectionRows.ContactRow.rawValue:
                let alertVC = UIAlertController(title: "Get in Touch", message: nil, preferredStyle: .ActionSheet)
                alertVC.addAction(
                    UIAlertAction(title: "Visit the Website", style: .Default, handler: { action in
                        let safariVC = SFSafariViewController(URL: NSURL(string: "http://www.ackermann.io/quakes")!)
                        safariVC.view.tintColor = StyleController.darkerMainAppColor
                        dispatch_async(dispatch_get_main_queue()) {
                            self.presentViewController(safariVC, animated: true, completion: nil)
                        }
                    })
                )
                alertVC.addAction(
                    UIAlertAction(title: "Email the Developer", style: .Default, handler: { action in
                        let mailVC = MFMailComposeViewController()
                        mailVC.setSubject("Quakes Feedback")
                        mailVC.setToRecipients(["support@ackermann.io"])
                        let devInfo = "• iOS Version: \(UIDevice.currentDevice().deviceIOSVersion)<br>• Hardware: \(UIDevice.currentDevice().deviceModel)<br>• App Version: \(UIDevice.currentDevice().appVersionAndBuildString)<br>• Has Supported: \(SettingsController.sharedController.hasSupported ? "Yes" : "No")"
                        mailVC.setMessageBody("<br><br><br><br><br><br><br><br><br><br><br><br><hr> <center>Developer Info</center> <br>\(devInfo)<hr>", isHTML: true)
                        mailVC.mailComposeDelegate = self
                        self.presentViewController(mailVC, animated: true, completion: nil)
                    })
                )
                alertVC.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                presentViewController(alertVC, animated: true, completion: nil)
                break
                
            case GeneralSectionRows.RemoveAdsRow.rawValue:
                navigationController?.pushViewController(RemoveAdsViewController(), animated: true)
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.UserSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.LimitRow.rawValue:
                let values = [
                    SettingsController.APIFetchSize.Small.rawValue,
                    SettingsController.APIFetchSize.Medium.rawValue,
                    SettingsController.APIFetchSize.Large.rawValue,
                    SettingsController.APIFetchSize.ExtraLarge.rawValue
                ]
                let labels = [
                    SettingsController.APIFetchSize.Small.displayString(),
                    SettingsController.APIFetchSize.Medium.displayString(),
                    SettingsController.APIFetchSize.Large.displayString(),
                    SettingsController.APIFetchSize.ExtraLarge.displayString()
                ]
                let detailLabels = values.map { String($0) }
                
                let index: Int = values.indexOf(SettingsController.sharedController.fetchLimit.rawValue)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: detailLabels, footerDescription: "A larger fetch size will take longer to load.")
                let pvc = PickerViewController(type: .Limit, data: data, title: "Fetch Size")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            case UserSectionRows.RadiusRow.rawValue:
                let values = [
                    SettingsController.SearchRadiusSize.Small.rawValue,
                    SettingsController.SearchRadiusSize.Medium.rawValue,
                    SettingsController.SearchRadiusSize.Large.rawValue,
                    SettingsController.SearchRadiusSize.ExtraLarge.rawValue
                ]
                let labels = [
                    SettingsController.SearchRadiusSize.Small.displayString(),
                    SettingsController.SearchRadiusSize.Medium.displayString(),
                    SettingsController.SearchRadiusSize.Large.displayString(),
                    SettingsController.SearchRadiusSize.ExtraLarge.displayString()
                ]
                
                let detailLabels = values.map { formatter.stringFromDistance(CLLocationDistance($0 * 1000)) }
                
                let index: Int = values.indexOf(SettingsController.sharedController.searchRadius.rawValue)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: detailLabels, footerDescription: "A smaller radius will yield more location specific quakes.")
                let pvc = PickerViewController(type: .Radius, data: data, title: "Search Radius")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.ExtraSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                if let url = NSURL(string: "http://www.ackermann.io/privacy") {
                    let safariVC = SFSafariViewController(URL: url)
                    safariVC.view.tintColor = StyleController.darkerMainAppColor
                    presentViewController(safariVC, animated: true, completion: nil)
                }
                break
                
            case GeneralSectionRows.RemoveAdsRow.rawValue:
                if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
                break
                
            default:
                break
            }
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == TableSections.UserSection.rawValue && indexPath.row == UserSectionRows.UnitRow.rawValue {
            return false
        }
        else {
            return true
        }
    }

}

extension SettingsViewController: MFMailComposeViewControllerDelegate
{
    
    // MARK: - MFMailComposeViewController Delegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension SettingsViewController: PickerViewControllerDelegate
{
    
    // MARK: - PickerViewController Delegate
    func pickerViewController(pvc: PickerViewController, didPickObject object: AnyObject) {
        tableView.reloadData()
        
        switch pvc.type {
            
        case .Limit:
            SettingsController.sharedController.fetchLimit = SettingsController.APIFetchSize.closestValueForInteger(object as! Int)
            TelemetryController.sharedController.logFetchSizeChange(object as! Int)
            break
            
        case .Radius:
            SettingsController.sharedController.searchRadius = SettingsController.SearchRadiusSize.closestValueForInteger(object as! Int)
            TelemetryController.sharedController.logNearbyRadiusChanged(object as! Int)
            break
            
        default:
            fatalError("Unhandled picker vc type in settings vc: \(pvc.type)")
            
        }
    }
    
}
