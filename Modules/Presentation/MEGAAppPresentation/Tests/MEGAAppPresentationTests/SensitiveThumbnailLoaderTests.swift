@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import SwiftUI
import XCTest

final class SensitiveThumbnailLoaderTests: XCTestCase {
    
    func testInitialImage_invalidAccount_shouldReturnImageContainerWithoutSensitivity() {
        let node = NodeEntity(name: "test.jpg", handle: 1, isMarkedSensitive: true)
        let imageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(initialImage: imageContainer)
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false)
        )
        
        XCTAssertTrue(sut.initialImage(for: node, type: .thumbnail, placeholder: { Image("heart") })
            .isEqual(imageContainer))
    }
    
    func testInitialImage_nodeNotMarkedSensitive_shouldReturnPlaceholder() {
        let node = NodeEntity(name: "test.jpg", handle: 1)
        let placeholder: Image = Image("heart")
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true)
        )
        
        XCTAssertTrue(sut.initialImage(for: node, type: .thumbnail, placeholder: { placeholder })
            .isEqual(ImageContainer(image: placeholder, type: .placeholder)))
    }
    
    func testInitialImage_nodeMarkedSensitive_shouldReturnSensitiveContainer() {
        let node = NodeEntity(name: "test.jpg", handle: 1, isMarkedSensitive: true)
        let placeholder: Image = Image("heart")
        let image = Image("folder")
        let type = ImageType.thumbnail
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: type)
        let thumbnailLoader = MockThumbnailLoader(initialImage: thumbnailContainer)
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true)
        )
        
        let expected = SensitiveImageContainer(image: image, type: type,
                                               isSensitive: node.isMarkedSensitive)
        XCTAssertTrue(sut.initialImage(for: node, type: .thumbnail, placeholder: { placeholder }).isEqual(expected))
    }
    
    func testInitialImagePlaceholder_nodeNotMarkedAsSensitive_shouldReturnPlaceholderProvided() {
        let node = NodeEntity(name: "test.jpg", handle: 1)
        
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true)
        )

        let expectedImage = Image("folder")
        XCTAssertTrue(sut.initialImage(for: node, type: .thumbnail, placeholder: { expectedImage })
            .isEqual(ImageContainer(image: expectedImage, type: .placeholder)))
    }
    
    func testLoadImage_invalidAccount_shouldNotReturnSensitiveImageContainer() async throws {
        let node = NodeEntity(name: "test.jpg", handle: 1, isMarkedSensitive: true)
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: (any ImageContaining).self)
        defer { continuation.finish() }
        
        let thumbnailLoader = MockThumbnailLoader(loadImage: stream.eraseToAnyAsyncSequence())
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false)
        )
        
        var iterator = try await sut.loadImage(for: node, type: .preview).makeAsyncIterator()
        
        let thumbnailImage = Image("folder")
        let thumbnailType = ImageType.thumbnail
        let expectedImageContainer = ImageContainer(image: thumbnailImage, type: thumbnailType)
        continuation.yield(expectedImageContainer)
        
        let sensitiveThumbnailValue = await iterator.next()
        
        XCTAssertTrue(try XCTUnwrap(sensitiveThumbnailValue)
            .isEqual(expectedImageContainer))
        
        let previewImage = Image("heart")
        let previewType = ImageType.thumbnail
        let expectedPreviewValue = ImageContainer(image: previewImage, type: previewType)
        continuation.yield(expectedPreviewValue)
        
        let sensitivePreviewValue = await iterator.next()
        
        XCTAssertTrue(try XCTUnwrap(sensitivePreviewValue)
            .isEqual(expectedPreviewValue))
    }
    
    func testLoadImage_nodeMarkedSensitive_shouldReturnTrueOnAllValuesYielded() async throws {
        let node = NodeEntity(name: "test.jpg", handle: 1, isMarkedSensitive: true)
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: (any ImageContaining).self)
        defer { continuation.finish() }
        
        let thumbnailLoader = MockThumbnailLoader(loadImage: stream.eraseToAnyAsyncSequence())
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true)
        )
        
        var iterator = try await sut.loadImage(for: node, type: .preview).makeAsyncIterator()
        
        let thumbnailImage = Image("folder")
        let thumbnailType = ImageType.thumbnail
        continuation.yield(ImageContainer(image: thumbnailImage, type: thumbnailType))
        
        let sensitiveThumbnailValue = await iterator.next()
        let expectedThumbnailValue = SensitiveImageContainer(image: thumbnailImage, type: thumbnailType, isSensitive: node.isMarkedSensitive)
        
        XCTAssertTrue(try XCTUnwrap(sensitiveThumbnailValue).isEqual(expectedThumbnailValue))
        
        let previewImage = Image("heart")
        let previewType = ImageType.thumbnail
        continuation.yield(ImageContainer(image: previewImage, type: previewType))
        
        let sensitivePreviewValue = await iterator.next()
        let expectedPreviewValue = SensitiveImageContainer(image: previewImage, type: previewType, isSensitive: node.isMarkedSensitive)
        
        XCTAssertTrue(try XCTUnwrap(sensitivePreviewValue).isEqual(expectedPreviewValue))
    }
    
    func testLoadImage_nodeNotMarkedSensitive_shouldReturnInheritedSensitivityOnAllYieldedItems() async throws {
        let node = NodeEntity(name: "test.jpg", handle: 1, isMarkedSensitive: false)
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: (any ImageContaining).self)
        defer { continuation.finish() }
        
        let inheritedSensitivity = false
        let thumbnailLoader = MockThumbnailLoader(loadImage: stream.eraseToAnyAsyncSequence())
        let nodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .success(inheritedSensitivity))
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: nodeUseCase
        )
        
        var iterator = try await sut.loadImage(for: node, type: .preview).makeAsyncIterator()
        
        let thumbnailImage = Image("folder")
        let thumbnailType = ImageType.thumbnail
        continuation.yield(ImageContainer(image: thumbnailImage, type: thumbnailType))
        
        let sensitiveThumbnailValue = await iterator.next()
        let expectedThumbnailValue = SensitiveImageContainer(
            image: thumbnailImage, type: thumbnailType, isSensitive: inheritedSensitivity)
        
        XCTAssertTrue(try XCTUnwrap(sensitiveThumbnailValue).isEqual(expectedThumbnailValue))
        
        let previewImage = Image("heart")
        let previewType = ImageType.thumbnail
        continuation.yield(ImageContainer(image: previewImage, type: previewType))
        
        let sensitivePreviewValue = await iterator.next()
        let expectedPreviewValue = SensitiveImageContainer(
            image: previewImage, type: previewType, isSensitive: inheritedSensitivity)
        
        XCTAssertTrue(try XCTUnwrap(sensitivePreviewValue).isEqual(expectedPreviewValue))
    }
    
    private func makeSUT(
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> SensitiveThumbnailLoader {
        SensitiveThumbnailLoader(
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
}
