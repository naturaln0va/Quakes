
import UIKit

class SeverityView: UIView
{

    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let locations: [CGFloat] = [0.0, 0.25, 0.75, 1.0]
        
        let colors = [
            StyleController.purpleColor.cgColor,
            StyleController.redQuakeColor.cgColor,
            StyleController.orangeQuakeColor.cgColor,
            StyleController.greenQuakeColor.cgColor
        ]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
        ctx?.drawLinearGradient(gradient!, start: CGPoint(x: rect.width, y: 0), end: CGPoint.zero, options: .drawsAfterEndLocation)
    }

}
