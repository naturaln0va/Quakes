
import UIKit
import MessageUI

class SettingsViewController: UITableViewController
{
    
    enum UserSectionRows: Int
    {
        case LimitRow
        case RadiusRow
        case TotalRows
    }
    
    enum GeneralSectionRows: Int
    {
        case RateRow
        case RemoveAdsRow
        case ContactRow
        case TotalRows
    }
    
    enum TableSections: Int
    {
        case UserSection
        case GeneralSection
        case TotalSections
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneButtonPressed")
    }
    
    // MARK: - Actions
    func doneButtonPressed()
    {
        dismissViewControllerAnimated(true, completion: nil)
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
        else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 1 ? "Quakes" + UIDevice.currentDevice().appVersionAndBuildString : nil
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
                cell.detailTextLabel?.text = SettingsController.sharedController.searchRadius.displayString()
                cell.accessoryType = .DisclosureIndicator
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.GeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                cell.textLabel?.text = "Rate Quakes"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case GeneralSectionRows.RemoveAdsRow.rawValue:
                cell.textLabel?.text = "Remove Ads"
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
        
        return cell
    }

}
