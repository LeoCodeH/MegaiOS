import MEGAAppSDKRepo
import MEGADomain

struct HandleConverter {
    static func chatIdHandleConverter(_ chadId: ChatIdEntity) -> String {
        MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo).base64Handle(forUserHandle: chadId) ?? "Unknown"
    }
}
