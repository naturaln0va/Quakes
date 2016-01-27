
import UIKit

class AboutViewController: UIViewController
{

    let webView = UIWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "About"
        
        webView.frame = view.bounds
        webView.backgroundColor = StyleController.backgroundColor
        view.addSubview(webView)
        
        guard let aboutHTMLString = String(contentsOfBundleFileNamed: "about.html") else {
            print("WARNING: Add the about HTML file to the project.")
            return
        }
        
        webView.loadHTMLString(aboutHTMLString, baseURL: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        webView.frame = view.bounds
    }

}