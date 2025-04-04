import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import MEGAPhotos
import MEGASwiftUI
import Testing

@Suite("AddToPlaylistViewModel Tests")
struct AddToPlaylistViewModelTests {
    private enum TestError: Error {
        case timeout
    }
    
    @Suite("Load video playlists")
    @MainActor
    struct LoadVideoPlaylist {
        @Test
        func load() async throws {
            let videoPlaylistOne = VideoPlaylistEntity(
                setIdentifier: SetIdentifier(handle: 1),
                modificationTime: try "2025-01-10T08:00:00Z".date)
            let videoPlaylistTwo = VideoPlaylistEntity(
                setIdentifier: SetIdentifier(handle: 2),
                modificationTime: try "2025-01-09T08:00:00Z".date)
            
            let videoPlaylistsUseCase = MockVideoPlaylistUseCase(
                userVideoPlaylistsResult: [videoPlaylistTwo, videoPlaylistOne])
            let sut = AddToPlaylistViewModelTests
                .makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
            
            #expect(sut.viewState == .loading)
            
            var cancellable: AnyCancellable?
            await confirmation("Playlist loaded") { playlistLoaded in
                cancellable = sut.$videoPlaylists
                    .dropFirst()
                    .sink {
                        #expect($0 ==  [videoPlaylistOne, videoPlaylistTwo])
                        playlistLoaded()
                    }
                
                await sut.loadVideoPlaylists()
            }
            #expect(sut.viewState == .ideal)
            cancellable?.cancel()
        }
        
        @Test("when no playlist loaded empty state should be shown")
        func empty() async throws {
            let videoPlaylistsUseCase = MockVideoPlaylistUseCase(
                userVideoPlaylistsResult: [])
            let sut = AddToPlaylistViewModelTests
                .makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
            
            #expect(sut.viewState == .loading)
            await confirmation("Album empty state triggered") { albumEmptyStateTriggered in
                let subscription = sut.$viewState
                    .dropFirst()
                    .sink {
                        #expect($0 == .empty)
                        albumEmptyStateTriggered()
                    }
                
                await sut.loadVideoPlaylists()
                subscription.cancel()
            }
        }
    }
    
    @Suite("Create playlist")
    @MainActor
    struct CreatePlaylist {
        @Test("Create playlist tapped toggle show playlist alert")
        func showPlaylistAlert() {
            let sut = makeSUT()
            
            #expect(sut.showCreatePlaylistAlert == false)
            
            sut.onCreatePlaylistTapped()
            
            #expect(sut.showCreatePlaylistAlert == true)
        }
        
        @Suite("Create alert")
        @MainActor
        struct CreateAlert {
            @Test("Alert view model shows correctly")
            func alertViewModel() {
                let sut = makeSUT()
                
                #expect(sut.alertViewModel() == TextFieldAlertViewModel(
                    title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
                    placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                    affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
                    destructiveButtonTitle: Strings.Localizable.cancel))
            }
            
            @Test("when create alert is shown and action is triggered then it should create playlist", arguments: [
                ("My Playlist", "My Playlist"),
                ("", Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder)])
            func createAlertView(playlistName: String, expectedName: String) async {
                let videoPlaylistsUseCase = MockVideoPlaylistUseCase()
                let sut = makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
                let alertViewModel = sut.alertViewModel()
                
                await confirmation("Ensure create user album created") { createdConfirmation in
                    let invocationTask = Task {
                        for await invocation in videoPlaylistsUseCase.invocationSequence {
                            #expect(invocation == .createVideoPlaylist(name: expectedName))
                            createdConfirmation()
                            break
                        }
                    }
                    alertViewModel.action?(playlistName)
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        invocationTask.cancel()
                    }
                    await invocationTask.value
                }
            }
            
            @Test("When nil action passed then it should not create playlist")
            func nilAction() async {
                let videoPlaylistsUseCase = MockVideoPlaylistUseCase()
                let sut = makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
                let alertViewModel = sut.alertViewModel()
                
                await confirmation("Ensure playlist is not created", expectedCount: 0) { createdConfirmation in
                    let invocationTask = Task {
                        for await _ in videoPlaylistsUseCase.invocationSequence {
                            createdConfirmation()
                        }
                    }
                    alertViewModel.action?(nil)
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        invocationTask.cancel()
                    }
                    await invocationTask.value
                }
            }
        }
        
        @Suite("Playlist updates")
        @MainActor
        struct PlaylistUpdates {
            @Test("On playlist updated load playlists")
            func monitorPlaylists() async {
                let (videoPlaylistsUpdatedStream, videoPlaylistsUpdatedContinuation) = AsyncStream.makeStream(of: Void.self)
                let videoPlaylist = VideoPlaylistEntity(
                    setIdentifier: SetIdentifier(handle: 1))
                let videoPlaylistsUseCase = MockVideoPlaylistUseCase(
                    userVideoPlaylistsResult: [videoPlaylist],
                    videoPlaylistsUpdatedAsyncSequence: videoPlaylistsUpdatedStream.eraseToAnyAsyncSequence())
                let sut = makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
                
                await confirmation("Ensure playlist is updated") { updateConfirmation in
                    let invocationTask = Task {
                        for await invocation in videoPlaylistsUseCase.invocationSequence {
                            #expect(invocation == .userVideoPlaylists)
                            updateConfirmation()
                            break
                        }
                    }
                    
                    videoPlaylistsUpdatedContinuation.yield(())
                    videoPlaylistsUpdatedContinuation.finish()
                    
                    await sut.monitorPlaylistUpdates()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        invocationTask.cancel()
                    }
                    await invocationTask.value
                    
                    #expect(sut.videoPlaylists == [videoPlaylist])
                }
            }
        }
    }
    
    @Suite("Add to items to collection view protocol conformance")
    @MainActor
    struct CollectionViewProtocolSuite {
        @Test
        func isItemsNotEmptyPublisher() async throws {
            let sut = makeSUT()
            
            try await confirmation("isItemsNotEmpty match publisher", expectedCount: 3) { confirmation in
                var cancellable: AnyCancellable?
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    var expectations = [false, true, false]
                    cancellable = sut.isItemsNotEmptyPublisher
                        .sink(receiveCompletion: {
                            cancellable?.cancel()
                            switch $0 {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }, receiveValue: {
                            #expect($0 == expectations.removeFirst())
                            confirmation()
                            if expectations.isEmpty {
                                cancellable?.cancel()
                                continuation.resume()
                            }
                        })
                    
                    sut.videoPlaylists = [.init(setIdentifier: SetIdentifier(handle: 1))]
                    sut.videoPlaylists = []
                }
            }
        }
        
        @Test
        func addItems() async {
            let identifier = SetIdentifier(handle: 4)
            let playlist = VideoPlaylistEntity(setIdentifier: identifier, name: "Playlist")
            let selection = SetSelection(
                mode: .single, editMode: .active)
            selection.toggle(identifier)
            
            let videos = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
            let addedPhotoCount = 1
            let videoPlaylistModificationUseCase = MockVideoPlaylistModificationUseCase(
                addToVideoPlaylistResult: .success(.init(success: UInt(addedPhotoCount), failure: 0))
            )
            let router = MockAddToCollectionRouter()
            let sut = makeSUT(
                setSelection: selection,
                videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
                addToCollectionRouter: router)
            sut.videoPlaylists = [playlist]
            
            let message = Strings.Localizable.Set.AddTo.Snackbar.message(addedPhotoCount)
                .replacingOccurrences(of: "[A]", with: playlist.name)
            await confirmation("Ensure dismissed and items added", expectedCount: 3) { addAlbumItems in
                let invocationTask = Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await useCaseInvocation in videoPlaylistModificationUseCase.invocationSequence {
                                #expect(useCaseInvocation == .addVideoToPlaylist(id: identifier.handle, nodes: videos))
                                addAlbumItems()
                                break
                            }
                        }
                        group.addTask {
                            var routerInvocations = [MockAddToCollectionRouter.Invocation.dismiss, .showSnackBar(message: message)]
                            for await routerInvocation in await router.invocationSequence {
                                #expect(routerInvocation == routerInvocations.removeFirst())
                                addAlbumItems()
                                if routerInvocations.isEmpty {
                                    break
                                }
                            }
                        }
                    }
                }
                
                sut.addItems(videos)
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
    }
    
    @MainActor
    private static func makeSUT(
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol = MockVideoPlaylistContentUseCase(),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .none),
        router: some VideoRevampRouting = MockVideoRevampRouter(),
        setSelection: SetSelection = SetSelection(),
        videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol = MockVideoPlaylistUseCase(),
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol = MockVideoPlaylistModificationUseCase(),
        addToCollectionRouter: some AddToCollectionRouting = MockAddToCollectionRouter()
    ) -> AddToPlaylistViewModel {
        .init(
            thumbnailLoader: thumbnailLoader,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            router: router,
            setSelection: setSelection,
            videoPlaylistsUseCase: videoPlaylistsUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            addToCollectionRouter: addToCollectionRouter
        )
    }
}
