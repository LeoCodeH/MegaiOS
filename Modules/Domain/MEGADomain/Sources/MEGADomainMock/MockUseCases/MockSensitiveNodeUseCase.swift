import AsyncAlgorithms
import MEGADomain
import MEGASwift

public final class MockSensitiveNodeUseCase: SensitiveNodeUseCaseProtocol {

    private let _isAccessible: Bool
    private let isInheritingSensitivityResult: Result<Bool, any Error>
    private let isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>]
    private let monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error>
    private let sensitivityChangesForNode: AnyAsyncSequence<Bool>
    private let _folderSensitivityChanged: AnyAsyncSequence<Void>
    
    public init(isAccessible: Bool = true,
                isInheritingSensitivityResult: Result<Bool, any Error> = .failure(GenericErrorEntity()),
                isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>] = [:],
                monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence(),
                sensitivityChangesForNode: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
                folderSensitivityChanged: AnyAsyncSequence<Void> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        _isAccessible = isAccessible
        self.isInheritingSensitivityResult = isInheritingSensitivityResult
        self.isInheritingSensitivityResults = isInheritingSensitivityResults
        self.monitorInheritedSensitivityForNode = monitorInheritedSensitivityForNode
        self.sensitivityChangesForNode = sensitivityChangesForNode
        _folderSensitivityChanged = folderSensitivityChanged
    }
    
    public func isAccessible() -> Bool {
        _isAccessible
    }
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        try await withCheckedThrowingContinuation {
            $0.resume(with: isInheritingSensitivityResult(for: node))
        }
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        switch isInheritingSensitivityResult(for: node) {
        case .success(let isSensitive):
           isSensitive
        case .failure(let error):
            throw error
        }
    }
    
    public func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        monitorInheritedSensitivityForNode
    }
    
    public func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        sensitivityChangesForNode
    }

    public func mergeInheritedAndDirectSensitivityChanges(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        merge(
            sensitivityChanges(for: node),
            monitorInheritedSensitivity(for: node)
        ).eraseToAnyAsyncThrowingSequence()
    }
    
    public func folderSensitivityChanged() -> AnyAsyncSequence<Void> {
        _folderSensitivityChanged
    }
    
    public func cachedInheritedSensitivity(for nodeHandle: HandleEntity) -> Bool? {
        nil
    }
}

// MARK: - Private Helpers
extension MockSensitiveNodeUseCase {
    private func isInheritingSensitivityResult(for node: NodeEntity) -> Result<Bool, any Error> {
        isInheritingSensitivityResults[node.handle] ?? isInheritingSensitivityResult
    }
}
