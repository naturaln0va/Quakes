
import UIKit

enum NotificationType: Int {
    case Auto
    case Nearby
    case World
    case Major
}

enum NotificationAmmount: Int {
    case NoLimit
    case Hourly
    case Daily
    case Weekly
}

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
    
    private let hasAttemptedNotificationKey = "hasAttemptedNotificationPermission"
    
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
            if sender.on {
                if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() where settings.types != .None {
                    SettingsController.sharedController.notificationsActive = true
                    tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                }
                else {
                    sender.setOn(false, animated: true)
                    if NSUserDefaults.standardUserDefaults().boolForKey(hasAttemptedNotificationKey) {
                        let alertView = UIAlertController(title: "Error", message: "Notification permission denied", preferredStyle: .Alert)
                        
                        alertView.addAction(UIAlertAction(title: "Open Settings", style: .Default, handler: { action in
                            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                        }))
                        
                        alertView.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                        
                        presentViewController(alertView, animated: true, completion: nil)
                    }
                    else {
                       NSUserDefaults.standardUserDefaults().setBool(true, forKey: hasAttemptedNotificationKey)
                        UIApplication.sharedApplication().registerUserNotificationSettings(
                            UIUserNotificationSettings(
                                forTypes: .Alert,
                                categories: nil
                            )
                        )
                    }
                }
                
            }
            else {
                SettingsController.sharedController.notificationsActive = false
                tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            }
            break
            
        default:
            break
        }
    }

    // MARK: - UITableView Data Source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.TotalSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ToggleNotifications.rawValue {
            return 1
        }
        else if section == TableSections.UserSettings.rawValue {
            return SettingsController.sharedController.notificationsActive ? UserSettingsRows.TotalRows.rawValue : 0
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
                
                switch SettingsController.sharedController.notificationType {
                case NotificationType.Auto.rawValue:
                    cell.detailTextLabel?.text = "Automatic"
                    
                case NotificationType.Nearby.rawValue:
                    cell.detailTextLabel?.text = "Nearby"
                    
                case NotificationType.World.rawValue:
                    cell.detailTextLabel?.text = "World"
                    
                case NotificationType.Major.rawValue:
                    cell.detailTextLabel?.text = "Major"
                    
                default:
                    fatalError("Unhandled type stored in the settings.")
                }
            }
            else if indexPath.row == UserSettingsRows.AmmountRow.rawValue {
                cell.textLabel?.text = "Notification Amount"
                cell.accessoryType = .DisclosureIndicator
                
                switch SettingsController.sharedController.notificationAmount {
                case NotificationAmmount.NoLimit.rawValue:
                    cell.detailTextLabel?.text = "No Limit"
                    
                case NotificationAmmount.Hourly.rawValue:
                    cell.detailTextLabel?.text = "Hourly"

                case NotificationAmmount.Daily.rawValue:
                    cell.detailTextLabel?.text = "Daily"

                case NotificationAmmount.Weekly.rawValue:
                    cell.detailTextLabel?.text = "Weekly"
                    
                default:
                    fatalError("Unhandled amount stored in the settings.")
                }
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
        
        if indexPath.section == TableSections.UserSettings.rawValue {
            if indexPath.row == UserSettingsRows.TypeRow.rawValue {
                let values = [
                    NotificationType.Auto.rawValue,
                    NotificationType.Nearby.rawValue,
                    NotificationType.World.rawValue,
                    NotificationType.Major.rawValue
                ]
                let labels = [
                    "Last Quake Search",
                    "Nearby Quakes",
                    "World Quakes",
                    "Major Quakes"
                ]
                
                guard let index: Int = values.indexOf(SettingsController.sharedController.notificationType) else {
                    fatalError("There was an incorrect index stored for notification type.")
                }
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: nil, footerDescription: "The type of alerts you will be receiving.")
                let pvc = PickerViewController(type: .NotificationType, data: data, title: "Type")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
            }
            else if indexPath.row == UserSettingsRows.AmmountRow.rawValue {
                let values = [
                    NotificationAmmount.NoLimit.rawValue,
                    NotificationAmmount.Hourly.rawValue,
                    NotificationAmmount.Daily.rawValue,
                    NotificationAmmount.Weekly.rawValue
                ]
                let labels = [
                    "No Limit",
                    "Once an Hour",
                    "Once a Day",
                    "Once a Week"
                ]
                
                guard let index: Int = values.indexOf(SettingsController.sharedController.notificationAmount) else {
                    fatalError("There was an incorrect index stored for notification type.")
                }
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: nil, footerDescription: "You will only be notified if new quakes have happened within the selected limit.")
                let pvc = PickerViewController(type: .NotificationAmount, data: data, title: "Amount")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
            }
            else {
                fatalError("Unhandled table row, \(indexPath.row), in did select indexPath.")
            }
        }
        else {
            fatalError("Unhandled table section, \(indexPath.section), in did select indexPath.")
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == TableSections.ToggleNotifications.rawValue {
            return false
        }
        else {
            return true
        }
    }

}

extension NotificationSettingsViewController: PickerViewControllerDelegate
{
    
    // MARK: - PickerViewController Delegate
    func pickerViewController(pvc: PickerViewController, didPickObject object: AnyObject) {
        tableView.reloadData()
        
        switch pvc.type {
            
        case .NotificationType:
            SettingsController.sharedController.notificationType = object as! Int
            break
            
        case .NotificationAmount:
            SettingsController.sharedController.notificationAmount = object as! Int
            break
            
        default:
            fatalError("Unhandled picker vc type in notification settings vc: \(pvc.type)")
            
        }
    }
    
}
