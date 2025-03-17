import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import UIKit

final class AddPhoneNumberViewController: UIViewController, ViewType {
    // MARK: - Private properties
    @IBOutlet private weak var addPhoneNumberButton: UIButton!
    @IBOutlet private weak var notNowButton: UIButton!
    @IBOutlet private weak var dontShowAgainButton: UIButton!
    @IBOutlet private weak var addPhoneNumberTitle: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionActivityIndicator: UIActivityIndicatorView!
    
    // MARK: - Internal properties
    var viewModel: AddPhoneNumberViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        viewModel.dispatch(.onViewReady)
    }
    
    // MARK: - Configure views
    private func configureViews() {
        addPhoneNumberButton.setTitle(Strings.Localizable.addPhoneNumber, for: .normal)
        notNowButton.setTitle(Strings.Localizable.notNow, for: .normal)
        dontShowAgainButton.setTitle(Strings.Localizable.dontShowAgain, for: .normal)
        addPhoneNumberTitle.text = Strings.Localizable.addPhoneNumber
        
        setupColors()
    }
    
    private func setupColors() {
        view.backgroundColor = TokenColors.Background.page
        addPhoneNumberTitle.textColor = TokenColors.Text.primary
        descriptionLabel.textColor = TokenColors.Text.primary
        addPhoneNumberButton.mnz_setupPrimary()
        notNowButton.mnz_setupCancel()
        dontShowAgainButton.mnz_setupCancel()
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: AddPhoneNumberViewModel.Command) {
        switch command {
        case .configView(let hideDontShowAgain):
            dontShowAgainButton.isHidden = hideDontShowAgain
        case .showAchievementStorage(let storage):
            descriptionLabel.isHidden = false
            descriptionLabel.text = storage
            descriptionActivityIndicator.stopAnimating()
        case .loadAchievementError(let message):
            descriptionLabel.isHidden = false
            descriptionLabel.text = message
            descriptionActivityIndicator.stopAnimating()
        }
    }
    
    // MARK: - UI Actions
    @IBAction func didTapAddPhoneNumberButton() {
        viewModel.dispatch(.addPhoneNumber)
    }

    @IBAction func didTapNotNowButton() {
        viewModel.dispatch(.notNow)
    }
    
    @IBAction func didTapDontShowAgainButton() {
        viewModel.dispatch(.notShowAddPhoneNumberAgain)
    }
}
