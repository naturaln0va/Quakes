//
//  RateMyApp.swift
//  RateMyApp
//
//  Created by Jimmy Jose on 08/09/14.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

class RateMyApp: UIViewController {
    
    fileprivate let kTrackingAppVersion     = "kRateMyApp_TrackingAppVersion"
    fileprivate let kFirstUseDate			= "kRateMyApp_FirstUseDate"
    fileprivate let kAppUseCount			= "kRateMyApp_AppUseCount"
    fileprivate let kSpecialEventCount		= "kRateMyApp_SpecialEventCount"
    fileprivate let kDidRateVersion         = "kRateMyApp_DidRateVersion"
    fileprivate let kDeclinedToRate			= "kRateMyApp_DeclinedToRate"
    fileprivate let kRemindLater            = "kRateMyApp_RemindLater"
    fileprivate let kRemindLaterPressedDate	= "kRateMyApp_RemindLaterPressedDate"
    
    fileprivate var reviewURL = "https://itunes.apple.com/us/app/quakes-earthquake-utility/id1071904740?ls=1&mt=8"
    
    var promptAfterDays: Double = 30
    var promptAfterUses = 7
    var promptAfterCustomEventsCount = 25
    var daysBeforeReminding: Double = 3
    
    var alertTitle = "Rate the app"
    var alertMessage = "Ratings help others find this app."
    var alertOKTitle = "Rate it now"
    var alertCancelTitle = "Cancel"
    var alertRemindLaterTitle = "Remind me later"
    
    static let sharedInstance = RateMyApp()
    
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    fileprivate func initAllSettings() {
        let prefs = UserDefaults.standard
        
        prefs.set(getCurrentAppVersion(), forKey: kTrackingAppVersion)
        prefs.set(Date(), forKey: kFirstUseDate)
        prefs.set(1, forKey: kAppUseCount)
        prefs.set(0, forKey: kSpecialEventCount)
        prefs.set(false, forKey: kDidRateVersion)
        prefs.set(false, forKey: kDeclinedToRate)
        prefs.set(false, forKey: kRemindLater)
    }
    
    func trackEventUsage() {
        incrementValueForKey(name: kSpecialEventCount)
    }
    
    func trackAppUsage() {
        incrementValueForKey(name: kAppUseCount)
    }
    
    fileprivate var isFirstTime: Bool {
        let prefs = UserDefaults.standard
        
        let trackingAppVersion = prefs.object(forKey: kTrackingAppVersion) as? NSString
        
        if ((trackingAppVersion == nil) || !(getCurrentAppVersion().isEqual(to: trackingAppVersion! as String))) {
            return true
        }
        
        return false
    }
    
    fileprivate func incrementValueForKey(name: String) {
        if isFirstTime {
            initAllSettings()
        }
        else {
            let prefs = UserDefaults.standard
            let currentCount = prefs.integer(forKey: name)
            prefs.set(currentCount + 1, forKey: name)
        }
        
        if shouldShowAlert() {
            showRatingAlert()
        }
    }
    
    fileprivate func shouldShowAlert() -> Bool {
        let prefs = UserDefaults.standard
        
        let usageCount = prefs.integer(forKey: kAppUseCount)
        let eventsCount = prefs.integer(forKey: kSpecialEventCount)
        
        let firstUse = prefs.object(forKey: kFirstUseDate) as! Date
        
        let timeInterval = Date().timeIntervalSince(firstUse)
        
        let daysCount = ((timeInterval / 3600) / 24)
        
        let hasRatedCurrentVersion = prefs.bool(forKey: kDidRateVersion)
        
        let hasDeclinedToRate = prefs.bool(forKey: kDeclinedToRate)
        
        let hasChosenRemindLater = prefs.bool(forKey: kRemindLater)
        
        if hasDeclinedToRate {
            return false
        }
        
        if hasRatedCurrentVersion {
            return false
        }
        
        if hasChosenRemindLater {
            let remindLaterDate = prefs.object(forKey: kRemindLaterPressedDate) as! Date
            
            let timeInterval = Date().timeIntervalSince(remindLaterDate)
            
            let remindLaterDaysCount = ((timeInterval / 3600) / 24)
            
            return (remindLaterDaysCount >= daysBeforeReminding)
        }
        
        if usageCount >= promptAfterUses {
            return true
        }
        
        if daysCount >= promptAfterDays {
            return true
        }
        
        if eventsCount >= promptAfterCustomEventsCount {
            return true
        }
        
        return false
    }
    
    func showRatingAlert() {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: alertOKTitle, style: .default, handler: { alertAction in
            self.okButtonPressed()
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: alertCancelTitle, style: .cancel, handler: { alertAction in
            self.cancelButtonPressed()
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: alertRemindLaterTitle, style: .default, handler: { alertAction in
            self.remindLaterButtonPressed()
            alert.dismiss(animated: true, completion: nil)
        }))
        
        let appDelegate = UIApplication.shared.delegate as! WindowController
        let controller = appDelegate.window?.rootViewController
        
        controller?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func okButtonPressed(){
        UserDefaults.standard.set(true, forKey: kDidRateVersion)
        if let appStoreURL = URL(string: reviewURL) {
            UIApplication.shared.openURL(appStoreURL)
        }
    }
    
    fileprivate func cancelButtonPressed() {
        UserDefaults.standard.set(true, forKey: kDeclinedToRate)
    }
    
    fileprivate func remindLaterButtonPressed() {
        UserDefaults.standard.set(true, forKey: kRemindLater)
        UserDefaults.standard.set(Date(), forKey: kRemindLaterPressedDate)
    }
    
    fileprivate func getCurrentAppVersion() -> NSString {
        return (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! NSString)
    }
    
}
