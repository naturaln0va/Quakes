
import UIKit

struct PickerData {
    
    var currentIndex: Int
    var values: [Any]
    var labels: [String]
    var detailLabels: [String]?
    var footerDescription: String?
    var count: Int {
        get {
            return values.count
        }
    }
    
    init(values: [Any], currentIndex: Int, labels: [String], detailLabels: [String]? = nil, footerDescription: String? = nil) {
        self.values = values
        self.currentIndex = currentIndex
        self.labels = labels
        self.detailLabels = detailLabels ?? nil
        self.footerDescription = footerDescription ?? nil
    }
}

enum PickerType {
    case limit
    case radius
    case notificationType
    case notificationAmount
}

protocol PickerViewControllerDelegate: class {
    func pickerViewController(_ pvc: PickerViewController, didPickObject object: Any)
}

class PickerViewController: UITableViewController {
    
    let type: PickerType
    var dataForPicker: PickerData!
    weak var delegate: PickerViewControllerDelegate?
    
    init(type: PickerType, data: PickerData, title: String) {
        self.type = type
        super.init(style: .plain)
        dataForPicker = data
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.backgroundColor = StyleController.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        
        if data.footerDescription != nil {
            let footerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: 64.0))
            footerView.backgroundColor = UIColor.clear
            
            let descriptionLabel = UILabel()
            descriptionLabel.numberOfLines = 0
            descriptionLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
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
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let coloredBackgroundView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: 24.0))
        coloredBackgroundView.backgroundColor = UIColor.clear
        return coloredBackgroundView
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        return data.count
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "defaultCell")
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        cell.textLabel?.text = data.labels[indexPath.row]
        
        if let detailLabels = data.detailLabels {
            cell.detailTextLabel?.text = detailLabels[indexPath.row]
        }
        
        if data.currentIndex == indexPath.row {
            cell.tintColor = StyleController.darkerMainAppColor
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        if let delegate = delegate {
            delegate.pickerViewController(self, didPickObject: data.values[indexPath.row])
        }
        _ = navigationController?.popViewController(animated: true)
    }
    
}
