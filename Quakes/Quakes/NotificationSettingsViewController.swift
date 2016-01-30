
import UIKit

class NotificationSettingsViewController: UITableViewController
{
    enum TableSections: Int {
        case ToggleNotifications
        case UserSettings
        case TotalSections
    }
    
    enum UserSettingsRows: Int {
        case TypeRow
        case AmmountRow
        case TotalRows
    }
    
    enum SwitchTag: Int {
        case Activate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Notification Settings"
        
        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.backgroundColor = StyleController.backgroundColor
    }
    
    // MARK: Actions
    func switchWasToggled(sender: UISwitch)
    {
        switch sender.tag {
            
        case SwitchTag.Activate.rawValue:
            SettingsController.sharedController.notificationsActive = sender.on
            tableView.reloadData()
            
            if sender.on {
                // check if there is permission, if not request it, if blocked open settings
                
                    // show the rest of the table
                    // save the setting
            }
            else {
                // hide the settings
                // save the setting
            }
            break
            
        default:
            break
        }
    }

    // MARK: - UITableView Data Source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return SettingsController.sharedController.notificationsActive ? TableSections.TotalSections.rawValue : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ToggleNotifications.rawValue {
            return 1
        }
        else if section == TableSections.UserSettings.rawValue {
            return UserSettingsRows.TotalRows.rawValue
        }
        else {
            fatalError("Unhandled table section, \(section), for row count.")
        }
    }
    
    // MARK: UITableView Delegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "defaultCell")
        
        if indexPath.section == TableSections.ToggleNotifications.rawValue {
            cell.textLabel?.text = "Allow Quake Notifications"
            
            let activeSwitch = UISwitch()
            activeSwitch.tag = SwitchTag.Activate.rawValue
            activeSwitch.on = SettingsController.sharedController.notificationsActive
            activeSwitch.addTarget(
                self,
                action: "switchWasToggled:",
                forControlEvents: .ValueChanged
            )
            
            cell.accessoryView = activeSwitch
        }
        else if indexPath.section == TableSections.UserSettings.rawValue {
            if indexPath.row == UserSettingsRows.TypeRow.rawValue {
                cell.textLabel?.text = "Notification Type"
                cell.accessoryType = .DisclosureIndicator
            }
            else if indexPath.row == UserSettingsRows.AmmountRow.rawValue {
                cell.textLabel?.text = "Ammount of Notifications"
                cell.accessoryType = .DisclosureIndicator
            }
            else {
                fatalError("Unhandled table row, \(indexPath.row), in cell for row")
            }
        }
        else {
            fatalError("Unhandled table section, \(indexPath.section), in cell for row.")
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
