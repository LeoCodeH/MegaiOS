import MEGASdk

/// A thread-safe wrapper for MEGACancelToken that ensures cancellation is performed safely across multiple threads.
public struct ThreadSafeCancelToken: @unchecked Sendable {
    /// The underlying cancellation token.
    public let value: MEGACancelToken

    /// A private serial dispatch queue to ensure thread-safe operations on the cancellation token.
    private let queue = DispatchQueue(label: "ThreadSafeCancelTokenSerialQueue")
    
    public init(value: MEGACancelToken = MEGACancelToken()) { 
        self.value = value
    }

    /// Cancels the underlying MEGACancelToken in a thread-safe manner.
    ///
    /// This method ensures that the cancellation token is only cancelled once, even if called from multiple threads.
    public func cancel() {
        queue.async {
            if !value.isCancelled {
                value.cancel()
            }
        }
    }
}
