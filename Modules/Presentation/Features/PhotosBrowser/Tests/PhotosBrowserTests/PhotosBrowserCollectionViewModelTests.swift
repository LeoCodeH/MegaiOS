import Combine
import Foundation
@preconcurrency import MEGAAppPresentation
import MEGADomain
import MEGATest
@testable @preconcurrency import PhotosBrowser
import Testing

struct PhotosBrowserCollectionViewModelTests {
    
    @MainActor
    @Test func testInitialMediaAssets() {
        let initialAssets = [
            PhotosBrowserLibraryEntity(handle: 0, base64Handle: "0", name: "test_0", modificationTime: Date.now),
            PhotosBrowserLibraryEntity(handle: 1, base64Handle: "1", name: "test_1", modificationTime: Date.now)
        ]
        let library = MediaLibrary(assets: initialAssets, currentIndex: 0)
        let viewModel = PhotosBrowserCollectionViewModel(library: library)
        
        #expect(viewModel.library.assets.count == initialAssets.count)
    }
    
    @Test func mediaAssetsUpdatesWhenLibraryAssetsChange() async {
        let initialAssets = [PhotosBrowserLibraryEntity(handle: 0, base64Handle: "0", name: "test_0", modificationTime: Date.now)]
        let updatedAssets = [
            PhotosBrowserLibraryEntity(handle: 1, base64Handle: "1", name: "test_1", modificationTime: Date.now),
            PhotosBrowserLibraryEntity(handle: 1, base64Handle: "2", name: "test_2", modificationTime: Date.now)
        ]
        let library = MediaLibrary(assets: initialAssets, currentIndex: 0)
        let viewModel = PhotosBrowserCollectionViewModel(library: library)
        
        var receivedMediaAssets: [PhotosBrowserLibraryEntity]?
        var cancellables = Set<AnyCancellable>()
        
        await confirmation("mediaAssets should update when library.assets changes") { confirm in
            viewModel.library.$assets
                .dropFirst()
                .sink { newAssets in
                    receivedMediaAssets = newAssets
                    confirm()
                }
                .store(in: &cancellables)
            
            library.assets = updatedAssets
        }
        
        #expect(receivedMediaAssets?.count == updatedAssets.count)
        #expect(viewModel.library.assets.count == updatedAssets.count)
    }
}
