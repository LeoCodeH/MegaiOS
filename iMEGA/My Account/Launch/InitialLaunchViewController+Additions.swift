import Foundation
import MEGAAppPresentation

extension InitialLaunchViewController {
    @objc func createViewModel() {
        viewModel = InitialLaunchViewModel(tracker: DIContainer.tracker)
    }
    
    @objc func didTapSetupButton() {
        viewModel.dispatch(.didTapSetUpMEGAButton)
    }
    
    @objc func didTapSkipSetupButton() {
        viewModel.dispatch(.didTapSkipSetUpButton)
    }
}
