@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import XCTest

final class ThumbnailLoaderFactoryTests: XCTestCase {
    
    func testMakeThumbnailLoader_configIsGeneral_shouldReturnThumbnailLoaderInstance() {
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .general, thumbnailUseCase: MockThumbnailUseCase())
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_configIsSensitiveIfFeatureFlagOn_shouldReturnSensitiveThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .sensitive(sensitiveNodeUseCase: MockSensitiveNodeUseCase()),
                                 thumbnailUseCase: MockThumbnailUseCase(),
                                 remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
        
        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_configIsSensitiveIfFeatureFlagOff_shouldReturnGeneralThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .sensitive(sensitiveNodeUseCase: MockSensitiveNodeUseCase()),
                                 thumbnailUseCase: MockThumbnailUseCase(),
                                 remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]))
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
    }
    
    // MARK: MakeThumbnailLoder with fallback
    
    func testMakeThumbnailLoaderWithFallback_configIsGeneral_shouldReturnThumbnailLoaderInstance() {
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(
                config: .generalWithFallBackIcon(nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: anyData())),
                thumbnailUseCase: MockThumbnailUseCase()
            )
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoaderWithFallbackIcon)
    }
    
    func testMakeThumbnailLoaderWithFallback_configIsSensitiveIfFeatureFlagOn_shouldReturnSensitiveThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(
                config: .sensitiveWithFallbackIcon(
                    sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
                    nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: anyData())
                ),
                thumbnailUseCase: MockThumbnailUseCase(),
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            )
        
        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    func testMakeThumbnailLoaderWithFallback_configIsSensitiveIfFeatureFlagOff_shouldReturnGeneralThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(
                config: .sensitiveWithFallbackIcon(
                    sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
                    nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: anyData())
                ),
                thumbnailUseCase: MockThumbnailUseCase(),
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
            )
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoaderWithFallbackIcon)
    }
    
    private func anyData() -> Data {
        "any-data".data(using: .utf8)!
    }
}
