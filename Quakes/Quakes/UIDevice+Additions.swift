
import UIKit


extension UIDevice
{
    
    public var hasForceTouch: Bool {
        return UIScreen.main.traitCollection.forceTouchCapability == .available
    }
    
    public var deviceCode: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        
        let code = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return code
    }
    
    public var appVersionAndBuildString: String {
        let identifer = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return "\(identifer).\(build)"
    }
    
    public var deviceFamily: String {
        return UIDevice.current.model
    }
    
    public var deviceModel: String {
        var model: String
        let deviceCode = UIDevice().deviceCode
        switch deviceCode {
            
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9Inch"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12Inch"
            
        case "i386", "x86_64":                          model = "Simulator"
        default:                                        model = deviceCode
        }
        
        return model
    }
    
    public var deviceIOSVersion: String {
        return UIDevice.current.systemVersion
    }
    
}
