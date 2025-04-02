import ContentLibraries
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import SwiftUI

struct VisualMediaSearchResultFoundView: UIViewRepresentable {
    let results: VisualMediaSearchResults
    @Binding var selectedItem: VisualMediaSearchResultSelection?
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout(
                sectionProvider: { sectionIndex, _ in
                    guard let section = context.coordinator.dataSource?.sectionIdentifier(for: sectionIndex) else {
                        return nil
                    }
                    return VisualMediaSearchResultFoundCollectionSectionLayoutFactory()
                        .make(type: section)
                },
                configuration: UICollectionViewCompositionalLayoutConfiguration()
            )
        )
        collectionView.backgroundColor = TokenColors.Background.page
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(results: results)
    }
    
    func makeCoordinator() -> VisualMediaSearchResultFoundCollectionViewCoordinator {
        VisualMediaSearchResultFoundCollectionViewCoordinator(self)
    }
}
