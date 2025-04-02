import Foundation
import MEGAAppPresentation

struct HelpViewRouter: Routing {
    
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "HelpTableViewControllerID")
    }
    
    func start() {
        let viewController = build()
        presenter?.pushViewController(viewController, animated: true)
    }
}
