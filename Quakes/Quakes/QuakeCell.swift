
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
            colorView.backgroundColor = StyleController.redQuakeColor
        }
        else if quake.magnitude >= 3.0 {
            colorView.backgroundColor = StyleController.orangeQuakeColor
        }
        else {
            colorView.backgroundColor = StyleController.greenQuakeColor
        }
        
        colorView.layer.cornerRadius = 6.0
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if quakeToDisplay.magnitude >= 4.0 {
            colorView.backgroundColor = StyleController.redQuakeColor
        }
        else if quakeToDisplay.magnitude >= 3.0 {
            colorView.backgroundColor = StyleController.orangeQuakeColor
        }
        else {
            colorView.backgroundColor = StyleController.greenQuakeColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if quakeToDisplay.magnitude >= 4.0 {
            colorView.backgroundColor = StyleController.redQuakeColor
        }
        else if quakeToDisplay.magnitude >= 3.0 {
            colorView.backgroundColor = StyleController.orangeQuakeColor
        }
        else {
            colorView.backgroundColor = StyleController.greenQuakeColor
        }
    }
    
}
