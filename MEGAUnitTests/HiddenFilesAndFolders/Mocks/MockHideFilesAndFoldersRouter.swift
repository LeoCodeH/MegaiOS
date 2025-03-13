@testable import MEGA
import MEGADomain

class MockHideFilesAndFoldersRouter: HideFilesAndFoldersRouting {
    private(set) var nodes: [NodeEntity]?
    private(set) var showSeeUpgradePlansOnboardingCalled = 0
    private(set) var showShowFirstTimeOnboardingCalled = 0
    private(set) var dismissCalled = 0
    private(set) var showSnackBarMessages = [String]()
    private(set) var dismissCompletion: (() -> Void)?
    
    nonisolated init() {}
    
    func hideNodes(_ nodes: [NodeEntity]) {
        self.nodes = nodes
    }
    
    func showSeeUpgradePlansOnboarding() {
        showSeeUpgradePlansOnboardingCalled += 1
    }
    
    func showFirstTimeOnboarding(nodes: [NodeEntity]) {
        showShowFirstTimeOnboardingCalled += 1
    }
    
    func showOnboardingInfo() {
        
    }
    
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?) {
        dismissCompletion = completion
        dismissCalled += 1
    }
    
    func showSnackBar(message: String) {
        showSnackBarMessages.append(message)
    }
}
