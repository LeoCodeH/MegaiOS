import MEGADomain

public final class MockSupportUseCase: SupportUseCaseProtocol, @unchecked Sendable {
    let createSupportTicketResult: Result<Void, any Error>
    
    public var messages = [Message]()
    
    public enum Message: Equatable {
        case createSupportTicket(message: String)
    }

    public init(createSupportTicketResult: Result<Void, any Error> = .failure(GenericErrorEntity())) {
        self.createSupportTicketResult = createSupportTicketResult
    }

    public func createSupportTicket(
        withMessage message: String
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: createSupportTicketResult)
        }
        messages.append(.createSupportTicket(message: message))
    }
}
