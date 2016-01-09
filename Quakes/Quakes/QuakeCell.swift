
import UIKit

class QuakeCell: UITableViewCell
{
    
    static let reuseIdentifier = "QuakeCell"
    static let cellHeight: CGFloat = 85.0
    
    @IBOutlet var magnitudeLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var additionalInfoLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var colorView: UIView!
    
    var quakeToDisplay: Quake!
    
    func configure(quake: Quake) {
        quakeToDisplay = quake
        
        timestampLabel.text = relativeStringForDate(quake.timestamp)
        magnitudeLabel.text = Quake.magnitudeFormatter.stringFromNumber(quake.magnitude)
        
        additionalInfoLabel.text = quake.name
        
        cityLabel.text = quake.name.componentsSeparatedByString(" of ").last!
        
        if quake.magnitude >= 4.0 {
            colorView.backgroundColor = UIColor(red: 0.667,  green: 0.224,  blue: 0.224, alpha: 1.0)
        }
        else if quake.magnitude >= 3.0 {
            colorView.backgroundColor = UIColor(red: 0.799,  green: 0.486,  blue: 0.163, alpha: 1.0)
        }
        else {
            colorView.backgroundColor = UIColor(red: 0.180,  green: 0.533,  blue: 0.180, alpha: 1.0)
        }
        
        colorView.layer.cornerRadius = 6.0
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if quakeToDisplay.magnitude >= 4.0 {
            colorView.backgroundColor = UIColor(red: 0.667,  green: 0.224,  blue: 0.224, alpha: 1.0)
        }
        else if quakeToDisplay.magnitude >= 3.0 {
            colorView.backgroundColor = UIColor(red: 0.799,  green: 0.486,  blue: 0.163, alpha: 1.0)
        }
        else {
            colorView.backgroundColor = UIColor(red: 0.180,  green: 0.533,  blue: 0.180, alpha: 1.0)
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if quakeToDisplay.magnitude >= 4.0 {
            colorView.backgroundColor = UIColor(red: 0.667,  green: 0.224,  blue: 0.224, alpha: 1.0)
        }
        else if quakeToDisplay.magnitude >= 3.0 {
            colorView.backgroundColor = UIColor(red: 0.799,  green: 0.486,  blue: 0.163, alpha: 1.0)
        }
        else {
            colorView.backgroundColor = UIColor(red: 0.180,  green: 0.533,  blue: 0.180, alpha: 1.0)
        }
    }
    
}
