import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain

public final class PhotoYearCardViewModel: PhotoCardViewModel {
    private let photoByYear: PhotoByYear
    
    let title: String
    
    public init(photoByYear: PhotoByYear,
                thumbnailLoader: some ThumbnailLoaderProtocol,
                nodeUseCase: some NodeUseCaseProtocol,
                sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
                remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.photoByYear = photoByYear
        
        title = photoByYear.categoryDate.formatted(.dateTime.year().locale(.current))
        
        super.init(
            coverPhoto: photoByYear.coverPhoto,
            thumbnailLoader: thumbnailLoader,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
        )
    }
}
