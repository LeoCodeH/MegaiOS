import MEGADomain
import MEGASdk
import MEGASwift

public protocol SetAndElementUpdatesProviderProtocol: Sendable {
    
    /// Set updates from `MEGAGlobalDelegate` `onSetsUpdate` as an `AnyAsyncSequence`
    /// - Parameter filteredBy: By setting which SetTypeEntities you want to filter the yielded results. If either no filter is set or an empty filter is provided, then it will not filter yielded updates.
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `[SetEntity]` items until sequence terminated
    func setUpdates(filteredBy: [SetTypeEntity]) -> AnyAsyncSequence<[SetEntity]>
    
    /// SetElement updates from `MEGAGlobalDelegate` `onSetElementsUpdate` as an `AnyAsyncSequence`
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `[SetElementEntity]` items until sequence terminated
    func setElementUpdates() -> AnyAsyncSequence<[SetElementEntity]>
}

public struct SetAndElementUpdatesProvider: SetAndElementUpdatesProviderProtocol {
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func setUpdates(filteredBy: [SetTypeEntity]) -> AnyAsyncSequence<[SetEntity]> {
        AsyncStream { continuation in
            let delegate = SetUpdateGlobalDelegate(filterBy: filteredBy) { continuation.yield($0) }
            
            sdk.addMEGAGlobalDelegateAsync(delegate, queueType: .globalBackground)
            
            continuation.onTermination = { @Sendable _ in
                sdk.removeMEGAGlobalDelegateAsync(delegate)
            }
            
        }.eraseToAnyAsyncSequence()
    }
    
    public func setElementUpdates() -> AnyAsyncSequence<[SetElementEntity]> {
        AsyncStream { continuation in
            let delegate = SetElementUpdateGlobalDelegate { continuation.yield($0) }
            
            sdk.addMEGAGlobalDelegateAsync(delegate, queueType: .globalBackground)

            continuation.onTermination = { @Sendable _ in
                sdk.removeMEGAGlobalDelegateAsync(delegate)
            }
        }.eraseToAnyAsyncSequence()
    }
}

private final class SetUpdateGlobalDelegate: NSObject, MEGAGlobalDelegate, Sendable {
    
    private let filterBy: [SetTypeEntity]
    private let onUpdate: @Sendable ([SetEntity]) -> Void

    public init(filterBy: [SetTypeEntity], onUpdate: @Sendable @escaping ([SetEntity]) -> Void) {
        self.filterBy = filterBy
        self.onUpdate = onUpdate
        super.init()
    }

    func onSetsUpdate(_ api: MEGASdk, sets: [MEGASet]) {
        
        let albumSets = if filterBy.isNotEmpty {
            sets.toSetEntities().filter { filterBy.contains($0.setType) }
        } else {
            sets.toSetEntities()
        }
        
        guard albumSets.isNotEmpty else { return }
        
        onUpdate(albumSets)
    }
}

private final class SetElementUpdateGlobalDelegate: NSObject, MEGAGlobalDelegate, Sendable {
    
    private let onUpdate: @Sendable ([SetElementEntity]) -> Void

    public init(onUpdate: @Sendable @escaping ([SetElementEntity]) -> Void) {
        self.onUpdate = onUpdate
        super.init()
    }
    
    func onSetElementsUpdate(_ api: MEGASdk, setElements: [MEGASetElement]) {
        onUpdate(setElements.toSetElementsEntities())
    }
}
