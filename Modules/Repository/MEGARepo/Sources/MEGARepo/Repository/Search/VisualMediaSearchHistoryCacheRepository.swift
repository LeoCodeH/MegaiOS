import MEGADomain

/// In memory cache for search history items
public actor VisualMediaSearchHistoryCacheRepository: VisualMediaSearchHistoryRepositoryProtocol {
    public static var newRepo: VisualMediaSearchHistoryCacheRepository {
        .init()
    }

    private var recentSearches: [SearchTextHistoryEntryEntity] = []
    
    public init() { }
    
    public func history() async -> [SearchTextHistoryEntryEntity] {
        recentSearches
    }
    
    public func add(entry: SearchTextHistoryEntryEntity) async {
        if let existingIndex = recentSearches.firstIndex(
            where: { $0.query.localizedCaseInsensitiveContains(entry.query) }) {
            recentSearches.remove(at: existingIndex)
        }
        recentSearches.append(entry)
    }
    
    public func delete(entry: SearchTextHistoryEntryEntity) async {
        recentSearches.remove(object: entry)
    }
}
