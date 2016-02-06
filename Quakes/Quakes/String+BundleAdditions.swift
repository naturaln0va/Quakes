
import Foundation

extension String
{
    
    init?(contentsOfBundleFileNamed fileName: String) {
        let comps = fileName.componentsSeparatedByString(".")
        if let path = NSBundle.mainBundle().pathForResource(comps.first, ofType: comps.last) where comps.count == 2 {
            do {
                self = try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            }
            
            catch {
                print("Error searching for file: \(fileName)")
                return nil
            }
        }
        else {
            return nil
        }
    }
    
}
