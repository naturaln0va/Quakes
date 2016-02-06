
import UIKit

struct PickerData
{
    var currentIndex: Int
    var values: Array<AnyObject>
    var labels: Array<String>
    var detailLabels: Array<String>?
    var footerDescription: String?
    var count: Int {
        get {
            return values.count
        }
    }
    
    init(values: Array<AnyObject>, currentIndex: Int, labels: Array<String>, detailLabels: Array<String>? = nil, footerDescription: String? = nil)
    {
        self.values = values
        self.currentIndex = currentIndex
        self.labels = labels
        self.detailLabels = detailLabels ?? nil
        self.footerDescription = footerDescription ?? nil
    }
}

enum PickerType {
    case Limit
    case Radius
    case NotificationType
    case NotificationAmount
}

protocol PickerViewControllerDelegate: class {
    func pickerViewController(pvc: PickerViewController, didPickObject object: AnyObject)
}


class PickerViewController: UITableViewController
{
    
    let type: PickerType
    var dataForPicker: PickerData!
    weak var delegate: PickerViewControllerDelegate?
    
    init(type: PickerType, data: PickerData, title: String)
    {
        self.type = type
        super.init(style: .Plain)
        dataForPicker = data
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        
        if data.footerDescription != nil {
            let footerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(tableView.bounds), height: 64.0))
            footerView.backgroundColor = UIColor.clearColor()
            
            let descriptionLabel = UILabel()
            descriptionLabel.numberOfLines = 0
            descriptionLabel.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightLight)
            descriptionLabel.text = data.footerDescription!
            descriptionLabel.bounds = footerView.bounds
            descriptionLabel.center = footerView.center
            descriptionLabel.frame.origin.x += 15.0
            descriptionLabel.frame.size.width -= 30.0
            footerView.addSubview(descriptionLabel)
            
            tableView.tableFooterView = footerView
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 35.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let coloredBackgroundView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(tableView.bounds), height: 24.0))
        coloredBackgroundView.backgroundColor = UIColor.clearColor()
        return coloredBackgroundView
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        return data.count
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "defaultCell")
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        cell.textLabel?.text = data.labels[indexPath.row]
        
        if let detailLabels = data.detailLabels {
            cell.detailTextLabel?.text = detailLabels[indexPath.row]
        }
        
        if data.currentIndex == indexPath.row {
            cell.tintColor = StyleController.darkerMainAppColor
            cell.accessoryType = .Checkmark
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        if let delegate = delegate {
            delegate.pickerViewController(self, didPickObject: data.values[indexPath.row])
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
}
