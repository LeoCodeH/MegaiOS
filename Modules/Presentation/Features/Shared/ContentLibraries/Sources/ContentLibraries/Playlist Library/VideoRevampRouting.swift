import MEGADomain
import MEGAPresentation
import SwiftUI

public struct VideoPlaylistContentSnackBarPresentationConfig {
    public let shouldShowSnackBar: Bool
    public let text: String?
    
    public init(shouldShowSnackBar: Bool = false, text: String?) {
        self.shouldShowSnackBar = shouldShowSnackBar
        self.text = text
    }
}

public protocol VideoRevampRouting: Routing {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity])
    func openMoreOptions(for video: NodeEntity, sender: Any)
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig)
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void)
    func popScreen()
    func openRecentlyWatchedVideos()
    
    associatedtype ShareLinkView: View
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> ShareLinkView
    func showOverDiskQuota()
}

extension VideoRevampRouting {
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity) {
        let presentationConfig = VideoPlaylistContentSnackBarPresentationConfig(shouldShowSnackBar: false, text: nil)
        self.openVideoPlaylistContent(for: videoPlaylistEntity, presentationConfig: presentationConfig)
    }
}
