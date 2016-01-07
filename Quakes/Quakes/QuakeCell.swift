
import UIKit

class QuakeCell: UITableViewCell
{
    
    static let reuseIdentifier = "QuakeCell"
    static let cellHeight: CGFloat = 85.0
    
    @IBOutlet var magnitudeLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var additionalInfoLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    
    func configure(quake: Quake) {
        timestampLabel.text = relativeStringForDate(quake.timestamp)
        magnitudeLabel.text = Quake.magnitudeFormatter.stringFromNumber(quake.magnitude)
        
        additionalInfoLabel.text = quake.name
        
        cityLabel.text = quake.coordinate.formatedString()
    }
    
}
