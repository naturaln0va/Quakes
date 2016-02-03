
import UIKit

typealias DismisalBlock = (()->())?

class TextBarAnimator: NSObject, UIViewControllerAnimatedTransitioning
{
    
    let duration: Double
    var presenting: Bool
    var originFrame: CGRect
    var dismissCompletionBlock: DismisalBlock
    
    init(duration: Double, presentingViewController presenting: Bool, originatingFrame frame: CGRect, completion: DismisalBlock) {
        self.duration = duration
        self.presenting = presenting
        self.originFrame = CGRect(x: frame.origin.x, y: 26, width: frame.width, height: frame.height)
        self.dismissCompletionBlock = completion
        super.init()
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView() else {
            print("Could not parse the container view when animating.")
            return
        }
        
        let fromViewControler = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toViewControler = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        let viewToFade = presenting ? toViewControler : fromViewControler
        
        guard let finderVC = viewToFade as? LocationFinderViewController else {
            print("viewToFade was not of type: 'LocationFinderViewController'.")
            return
        }
        
        finderVC.view.frame = UIScreen.mainScreen().bounds
        containerView.frame = UIScreen.mainScreen().bounds
        
        if presenting {
            let finalFrame = CGRect(
                origin: finderVC.searchTextField.frame.origin,
                size: CGSize(width: UIScreen.mainScreen().bounds.width - 27 * 2, height: finderVC.searchTextField.frame.height)
            )
            
            containerView.addSubview(finderVC.view)
            finderVC.view.alpha = 0.0
            
            finderVC.searchTextField.alpha = 0.0
            
            let buttonView = UIView(frame: originFrame)
            buttonView.backgroundColor = StyleController.searchBarColor
            buttonView.layer.cornerRadius = 4.0
            containerView.addSubview(buttonView)
            
            UIView.animateWithDuration(transitionDuration(transitionContext),
                animations: {
                    finderVC.view.alpha = 1.0
                    
                    finderVC.searchTextField.frame = finalFrame
                    buttonView.frame = finalFrame
                    buttonView.layer.cornerRadius = 0.0
                },
                completion: { _ in
                    finderVC.searchTextField.alpha = 1.0
                    buttonView.removeFromSuperview()
                    transitionContext.completeTransition(true)
            })
        }
        else {
            let finalFrame = CGRect(x: originFrame.origin.x, y: 26, width: originFrame.width, height: originFrame.height)
            
            guard let toVC = toViewControler else {
                print("the to view controller was nil.")
                return
            }
            
            containerView.addSubview(toVC.view)
            containerView.addSubview(finderVC.view)
            containerView.bringSubviewToFront(finderVC.view)
            
            let buttonView = UIView(frame: finderVC.searchTextField.frame)
            buttonView.backgroundColor = StyleController.searchBarColor
            buttonView.layer.cornerRadius = 0.0
            containerView.addSubview(buttonView)
            
            UIView.animateWithDuration(transitionDuration(transitionContext),
                animations: {
                    finderVC.view.alpha = 0.0
                    finderVC.searchTextField.alpha = 0.0
                    
                    finderVC.searchTextField.frame = finalFrame
                    buttonView.frame = finalFrame
                    buttonView.layer.cornerRadius = 4.0
                },
                completion: { _ in
                    buttonView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                    
                    if let completion = self.dismissCompletionBlock {
                        completion()
                    }
            })
        }
    }
    
}