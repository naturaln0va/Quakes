
import UIKit

protocol NotificationPromptViewControllerDelegate: class {
    func notificationPromptViewControllerDidAllowNotifications()
}


class NotificationPromptViewController: UIViewController
{
    
    weak var delegate: NotificationPromptViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SettingsController.sharedController.hasAttemptedNotificationPermission = true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: Actions
    @IBAction func allowNotificationsButtonPressed(sender: AnyObject) {
        delegate?.notificationPromptViewControllerDidAllowNotifications()
    }
    
    @IBAction func closeButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
