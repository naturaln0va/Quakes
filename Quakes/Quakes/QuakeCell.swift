
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
        
        timestampLabel.text = quake.timestamp.relativeString()
        magnitudeLabel.text = Quake.magnitudeFormatter.stringFromNumber(quake.magnitude)
        
        additionalInfoLabel.text = quake.nameString
        
        cityLabel.text = quake.name.componentsSeparatedByString(" of ").last!
        
        colorView.backgroundColor = quake.severityColor
        colorView.layer.cornerRadius = 6.0
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        colorView.backgroundColor = quakeToDisplay.severityColor
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        colorView.backgroundColor = quakeToDisplay.severityColor
    }
    
}
