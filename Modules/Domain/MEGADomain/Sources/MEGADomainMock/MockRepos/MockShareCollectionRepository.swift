import MEGADomain
import MEGASwift

public final class MockShareCollectionRepository: ShareCollectionRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockShareCollectionRepository()
    private let shareCollectionResults: [SetIdentifier: Result<String?, any Error>]
    private let disableCollectionShareResult: Result<Void, any Error>
    private let publicCollectionContentsResult: Result<SharedCollectionEntity, any Error>
    private let publicNodeResults: [HandleEntity: Result<NodeEntity, any Error>]
    private let copyPublicNodesResult: Result<[NodeEntity], any Error>
    
    @Atomic public var stopCollectionLinkPreviewCalled = 0
    
    public init(
        shareCollectionResults: [SetIdentifier: Result<String?, any Error>] = [:],
        disableCollectionShareResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        publicCollectionContentsResult: Result<SharedCollectionEntity, any Error> = .failure(GenericErrorEntity()),
        publicNodeResults: [HandleEntity: Result<NodeEntity, any Error>] = [:],
        copyPublicNodesResult: Result<[NodeEntity], any Error> = .failure(GenericErrorEntity())
    ) {
        self.shareCollectionResults = shareCollectionResults
        self.disableCollectionShareResult = disableCollectionShareResult
        self.publicCollectionContentsResult = publicCollectionContentsResult
        self.publicNodeResults = publicNodeResults
        self.copyPublicNodesResult = copyPublicNodesResult
    }
    
    public func shareCollectionLink(_ collection: SetEntity) async throws -> String? {
        guard let shareCollectionResult = shareCollectionResults.first(where: { $0.key == collection.setIdentifier })?.value else {
            return nil
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: shareCollectionResult)
        }
    }
    
    public func removeSharedLink(forCollectionId id: SetIdentifier) async throws {
        try await withCheckedThrowingContinuation {
            $0.resume(with: disableCollectionShareResult)
        }
    }
    
    public func publicCollectionContents(forLink link: String) async throws -> SharedCollectionEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicCollectionContentsResult)
        }
    }
    
    public func stopCollectionLinkPreview() {
        $stopCollectionLinkPreviewCalled.mutate { $0 += 1 }
    }
    
    public func publicNode(_ element: SetElementEntity) async throws -> NodeEntity? {
        guard let publicNodeResult = publicNodeResults.first(where: { $0.key == element.id })?.value else {
            return nil
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: publicNodeResult)
        }
    }
    
    public func copyPublicNodes(toFolder folder: NodeEntity, nodes: [NodeEntity]) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: copyPublicNodesResult)
        }
    }
}
