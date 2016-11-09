
import Foundation

extension String {
    
    init?(contentsOfBundleFileNamed fileName: String) {
        let comps = fileName.components(separatedBy: ".")
        if let path = Bundle.main.path(forResource: comps.first, ofType: comps.last), comps.count == 2 {
            do {
                self = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
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
