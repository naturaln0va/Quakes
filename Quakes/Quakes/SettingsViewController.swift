
import UIKit
import MapKit
import MessageUI
import SafariServices

class SettingsViewController: UITableViewController
{
    
    enum UserSectionRows: Int {
        case limitRow
        case radiusRow
        case unitRow
        case totalRows
    }
    
    enum GeneralSectionRows: Int {
        case removeAdsRow
        case rateRow
        case contactRow
        case totalRows
    }
    
    enum ExtraSectionRows: Int {
        case shareRow
        case permissionRow
        case privacyRow
        case totalRows
    }
    
    enum TableSections: Int {
        case userSection
        case generalSection
        case extraSection
        case totalSections
    }
    
    enum SwitchTag: Int {
        case unit
    }
    
    fileprivate lazy var formatter: MKDistanceFormatter = {
        let distFormatter = MKDistanceFormatter()
        distFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .imperial : .metric
        return distFormatter
    }()
    
    fileprivate var hasShared = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(SettingsViewController.doneButtonPressed))
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SettingsViewController.lowPowerModeChanged),
            name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    // MARK: - Actions
    func doneButtonPressed()
    {
        dismiss(animated: true, completion: nil)
    }
    
    func switchWasToggled(_ sender: UISwitch)
    {
        switch sender.tag {
            
        case SwitchTag.unit.rawValue:
            TelemetryController.sharedController.logUnitStyleToggled()
            SettingsController.sharedController.isUnitStyleImperial = !sender.isOn
            formatter.units = !sender.isOn ? .imperial : .metric
            tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            break
            
        default:
            break
        }
    }
    
    // MARK: - Notifications
    @objc fileprivate func lowPowerModeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return TableSections.totalSections.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == TableSections.generalSection.rawValue {
            return GeneralSectionRows.totalRows.rawValue
        }
        else if section == TableSections.userSection.rawValue {
            return UserSectionRows.totalRows.rawValue
        }
        else if section == TableSections.extraSection.rawValue {
            return ExtraSectionRows.totalRows.rawValue
        }
        else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == TableSections.userSection.rawValue && ProcessInfo.processInfo.isLowPowerModeEnabled {
            return "Some settings are limited because of Low Power Mode."
        }
        else {
            return section == TableSections.totalSections.rawValue - 1 ? "Quakes v" + UIDevice.current.appVersionAndBuildString : nil
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "defaultCell")
        
        if indexPath.section == TableSections.userSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.limitRow.rawValue:
                cell.textLabel?.text = "Fetch Size"
                cell.detailTextLabel?.text = SettingsController.sharedController.fetchLimit.displayString()
                cell.accessoryType = .disclosureIndicator
                break
                
            case UserSectionRows.radiusRow.rawValue:
                cell.textLabel?.text = "Nearby Radius"
                cell.detailTextLabel?.text = formatter.string(fromDistance: CLLocationDistance(SettingsController.sharedController.searchRadius.rawValue * 1000))
                cell.accessoryType = .disclosureIndicator
                break
                
            case UserSectionRows.unitRow.rawValue:
                cell.textLabel?.text = "Metric Unit Style"
                
                let unitSwitch = UISwitch()
                unitSwitch.tag = SwitchTag.unit.rawValue
                unitSwitch.isOn = !SettingsController.sharedController.isUnitStyleImperial
                unitSwitch.addTarget(
                    self,
                    action: #selector(SettingsViewController.switchWasToggled(_:)),
                    for: .valueChanged
                )
                
                cell.accessoryView = unitSwitch
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.generalSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.rateRow.rawValue:
                cell.textLabel?.text = "Rate on the App Store"
                cell.accessoryType = .disclosureIndicator
                break
                
            case GeneralSectionRows.removeAdsRow.rawValue:
                cell.textLabel?.text = "Support the App"
                cell.accessoryType = .disclosureIndicator
                break
                
            case GeneralSectionRows.contactRow.rawValue:
                cell.textLabel?.text = "Contact the Developer"
                cell.accessoryType = .disclosureIndicator
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.extraSection.rawValue {
            switch indexPath.row {
            case ExtraSectionRows.shareRow.rawValue:
                cell.textLabel?.text = "Spread the Word"
                cell.accessoryType = .disclosureIndicator
                if hasShared { cell.detailTextLabel?.text = "♥️" }
                break
                
            case ExtraSectionRows.privacyRow.rawValue:
                cell.textLabel?.text = "Privacy Policy"
                cell.accessoryType = .disclosureIndicator
                break
                
            case ExtraSectionRows.permissionRow.rawValue:
                cell.textLabel?.text = "App Permissions"
                cell.accessoryType = .disclosureIndicator
                break
                
            default:
                break
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == TableSections.generalSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.rateRow.rawValue:
                UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/us/app/quakes-earthquake-utility/id1071904740?ls=1&mt=8")!)
                break
                
            case GeneralSectionRows.contactRow.rawValue:
                let alertVC = UIAlertController(title: "Get in Touch", message: nil, preferredStyle: .actionSheet)
                alertVC.addAction(
                    UIAlertAction(title: "Visit the Website", style: .default, handler: { action in
                        let safariVC = SFSafariViewController(url: URL(string: "http://www.ackermann.io/quakes")!)
                        
                        if #available(iOS 10.0, *) {
                            safariVC.preferredControlTintColor = StyleController.darkerMainAppColor
                        }
                        else {
                            safariVC.view.tintColor = StyleController.darkerMainAppColor
                        }

                        DispatchQueue.main.async {
                            self.present(safariVC, animated: true, completion: nil)
                        }
                    })
                )
                
                if MFMailComposeViewController.canSendMail() {
                    alertVC.addAction(
                        UIAlertAction(title: "Email the Developer", style: .default, handler: { action in
                            let mailVC = MFMailComposeViewController()
                            mailVC.setSubject("Quakes Feedback")
                            mailVC.setToRecipients(["support@ackermann.io"])
                            let devInfo = "• iOS Version: \(UIDevice.current.deviceIOSVersion)<br>• Hardware: \(UIDevice.current.deviceModel)<br>• App Version: \(UIDevice.current.appVersionAndBuildString)<br>• Has Supported: \(SettingsController.sharedController.hasSupported ? "Yes" : "No")"
                            mailVC.setMessageBody("<br><br><br><br><br><br><br><br><br><br><br><br><hr> <center>Developer Info</center> <br>\(devInfo)<hr>", isHTML: true)
                            mailVC.mailComposeDelegate = self
                            self.present(mailVC, animated: true, completion: nil)
                        })
                    )
                }
                
                alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                present(alertVC, animated: true, completion: nil)
                break
                
            case GeneralSectionRows.removeAdsRow.rawValue:
                navigationController?.pushViewController(RemoveAdsViewController(), animated: true)
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.userSection.rawValue {
            guard !ProcessInfo.processInfo.isLowPowerModeEnabled else {
                let alertVC = UIAlertController(title: "Low Power Mode", message: "This setting cannot be changed when your device is in Low Power Mode.", preferredStyle: .alert)
                alertVC.addAction(
                    UIAlertAction(title: "Open Settings", style: .default, handler: { action in
                        if let url = URL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.openURL(url)
                        }
                    })
                )
                alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alertVC, animated: true, completion: nil)
                return
            }
            
            switch indexPath.row {
            case UserSectionRows.limitRow.rawValue:
                let values = [
                    SettingsController.APIFetchSize.small.rawValue,
                    SettingsController.APIFetchSize.medium.rawValue,
                    SettingsController.APIFetchSize.large.rawValue,
                    SettingsController.APIFetchSize.extraLarge.rawValue
                ]
                let labels = [
                    SettingsController.APIFetchSize.small.displayString(),
                    SettingsController.APIFetchSize.medium.displayString(),
                    SettingsController.APIFetchSize.large.displayString(),
                    SettingsController.APIFetchSize.extraLarge.displayString()
                ]
                let detailLabels = values.map { String($0) }
                
                let index: Int = values.index(of: SettingsController.sharedController.fetchLimit.rawValue)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: detailLabels, footerDescription: "A larger fetch size will take longer to load.")
                let pvc = PickerViewController(type: .limit, data: data, title: "Fetch Size")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            case UserSectionRows.radiusRow.rawValue:
                let values = [
                    SettingsController.SearchRadiusSize.small.rawValue,
                    SettingsController.SearchRadiusSize.medium.rawValue,
                    SettingsController.SearchRadiusSize.large.rawValue,
                    SettingsController.SearchRadiusSize.extraLarge.rawValue
                ]
                let labels = [
                    SettingsController.SearchRadiusSize.small.displayString(),
                    SettingsController.SearchRadiusSize.medium.displayString(),
                    SettingsController.SearchRadiusSize.large.displayString(),
                    SettingsController.SearchRadiusSize.extraLarge.displayString()
                ]
                
                let detailLabels = values.map { formatter.string(fromDistance: CLLocationDistance($0 * 1000)) }
                
                let index: Int = values.index(of: SettingsController.sharedController.searchRadius.rawValue)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: detailLabels, footerDescription: "A smaller radius will yield more location specific quakes.")
                let pvc = PickerViewController(type: .radius, data: data, title: "Search Radius")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.extraSection.rawValue {
            switch indexPath.row {
            case ExtraSectionRows.shareRow.rawValue:
                let shareVC = UIActivityViewController(
                    activityItems: ["Quakes: the best way to view details about earthquakes around the world! Check it out:\n", URL(string: "https://itunes.apple.com/us/app/quakes-earthquake-utility/id1071904740?ls=1&mt=8")!],
                    applicationActivities: nil
                )
                shareVC.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, activityError in
                    if completed {
                        self?.hasShared = true
                        self?.tableView.reloadData()
                    }
                }
                present(shareVC, animated: true, completion: nil)
                break
                
            case ExtraSectionRows.privacyRow.rawValue:
                if let url = URL(string: "http://www.ackermann.io/privacy") {
                    let safariVC = SFSafariViewController(url: url)
                    
                    if #available(iOS 10.0, *) {
                        safariVC.preferredControlTintColor = StyleController.darkerMainAppColor
                    }
                    else {
                        safariVC.view.tintColor = StyleController.darkerMainAppColor
                    }
                    
                    present(safariVC, animated: true, completion: nil)
                }
                break
                
            case ExtraSectionRows.permissionRow.rawValue:
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }
                break
                
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == TableSections.userSection.rawValue && indexPath.row == UserSectionRows.unitRow.rawValue {
            return false
        }
        else {
            return true
        }
    }

}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    // MARK: - MFMailComposeViewController Delegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension SettingsViewController: PickerViewControllerDelegate {
    
    // MARK: - PickerViewController Delegate
    func pickerViewController(_ pvc: PickerViewController, didPickObject object: Any) {
        tableView.reloadData()
        
        switch pvc.type {
            
        case .limit:
            SettingsController.sharedController.fetchLimit = SettingsController.APIFetchSize.closestValueForInteger(object as! Int)
            TelemetryController.sharedController.logFetchSizeChange(object as! Int)
            break
            
        case .radius:
            SettingsController.sharedController.searchRadius = SettingsController.SearchRadiusSize.closestValueForInteger(object as! Int)
            TelemetryController.sharedController.logNearbyRadiusChanged(object as! Int)
            break
            
        default:
            fatalError("Unhandled picker vc type in settings vc: \(pvc.type)")
            
        }
    }
    
}
