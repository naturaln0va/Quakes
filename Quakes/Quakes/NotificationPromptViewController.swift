
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
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: Actions
    @IBAction func allowNotificationsButtonPressed(_ sender: AnyObject) {
        delegate?.notificationPromptViewControllerDidAllowNotifications()
    }
    
    @IBAction func closeButtonPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
}
