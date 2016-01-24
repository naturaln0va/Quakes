
import UIKit

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
        case ContactRow
        case RemoceAdsRow
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
    
}
