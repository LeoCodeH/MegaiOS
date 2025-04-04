import MEGADomain

public struct MockSaveCollectionToFolderUseCase: SaveCollectionToFolderUseCaseProtocol {
    private let saveToFolderResult: Result<[NodeEntity], any Error>
    
    public init(saveToFolderResult: Result<[NodeEntity], any Error> = .failure(GenericErrorEntity())) {
        self.saveToFolderResult = saveToFolderResult
    }
    
    public func saveToFolder(collectionName: String,
                             nodes: [NodeEntity],
                             parent: NodeEntity) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: saveToFolderResult)
        }
    }
}
