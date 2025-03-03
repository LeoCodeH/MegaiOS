import ContentLibraries
import MEGADomain
import MEGAPresentation
import MEGASdk
import MEGASDKRepo
import SwiftUI
import Video

struct VideoRevampRouter: VideoRevampRouting {
    let explorerType: ExplorerTypeEntity
    let navigationController: UINavigationController?
    
    private let syncModel = VideoRevampSyncModel()
    private let nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    private var videoConfig: VideoConfig {
        .live()
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSearchRepo = FilesSearchRepository(sdk: sdk)
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeRepository: nodeRepository
        )
        let userVideoPlaylistsRepo = UserVideoPlaylistsRepository(
            sdk: sdk,
            setAndElementsUpdatesProvider: SetAndElementUpdatesProvider(sdk: sdk)
        )
        let sensitiveDisplayPreferenceUseCase = makeSensitiveDisplayPreferenceUseCase()
        let viewModel = VideoRevampTabContainerViewModel(videoSelection: VideoSelection(), syncModel: syncModel)
        let photoLibraryRepository = PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
        let videoPlaylistUseCase = VideoPlaylistUseCase(
            fileSearchUseCase: fileSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase
        )
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
        let videoPlaylistContentsUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
        let videoPlaylistModificationUseCase = VideoPlaylistModificationUseCase(
            userVideoPlaylistsRepository: userVideoPlaylistsRepo
        )
        let viewController = VideoRevampTabContainerViewController(
            viewModel: viewModel,
            fileSearchUseCase: fileSearchUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            videoPlaylistUseCase: videoPlaylistUseCase,
            videoPlaylistContentUseCase: videoPlaylistContentsUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: PreferenceUseCase.default,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
            ),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: sdk)),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: nodeRepository
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            videoConfig: .live(),
            router: self,
            featureFlagProvider: DIContainer.featureFlagProvider
        )
        return viewController
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) {
        let nodeInfoUseCase = NodeInfoUseCase()
        guard let selectedNode = nodeInfoUseCase.node(fromHandle: video.handle) else { return }
        let allNodes = allVideos.compactMap { nodeInfoUseCase.node(fromHandle: $0.handle) }
        
        guard let navigationController else { return }
        let nodeOpener = NodeOpener(navigationController: navigationController)
        nodeOpener.openNode(node: selectedNode, allNodes: allNodes)
    }
    
    func openMoreOptions(for videoNodeEntity: NodeEntity, sender: Any) {
        guard
            let navigationController,
            let videoMegaNode = videoNodeEntity.toMEGANode(in: MEGASdk.shared)
        else {
            return
        }
        
        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUseCase.isBackupNode(videoNodeEntity)
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
        )
        let viewController = NodeActionViewController(
            node: videoMegaNode,
            delegate: delegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: sender
        )
        viewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) {
        let userVideoPlaylistsRepo = UserVideoPlaylistsRepository.newRepo
        let fileSearchRepo = FilesSearchRepository.newRepo
        let sensitiveDisplayPreferenceUseCase = makeSensitiveDisplayPreferenceUseCase()
        let photoLibraryRepository = PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
        let nodeRepository = NodeRepository.newRepo
        let accountUseCase = AccountUseCase(
            repository: AccountRepository.newRepo)
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: accountUseCase)
        let videoPlaylistContentsUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let thumbnailUseCase = ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        let videoSelection = VideoSelection()
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeRepository: nodeRepository
        )
        let videoPlaylistUseCase = VideoPlaylistUseCase(
            fileSearchUseCase: fileSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase
        )
        let videoPlaylistModificationUseCase = VideoPlaylistModificationUseCase(
            userVideoPlaylistsRepository: userVideoPlaylistsRepo
        )
        let viewController = VideoPlaylistContentViewController(
            videoConfig: videoConfig,
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistUseCase: videoPlaylistUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: nodeRepository
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            router: self,
            presentationConfig: presentationConfig,
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: PreferenceUseCase.default,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
            ),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: MEGASdk.shared)),
            videoSelection: videoSelection,
            selectionAdapter: VideoPlaylistContentViewModelSelectionAdapter(selection: videoSelection),
            syncModel: syncModel
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) {
        guard
            let browserNavigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
            let browserVC = browserNavigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.browserAction = BrowserAction.selectVideo
        browserVC.selectedNodes = { selectedObjects in
            guard let selectedNodes = selectedObjects as? [MEGANode] else {
                completion([])
                return
            }
            completion(selectedNodes.toNodeEntities())
        }
        
        navigationController?.present(browserNavigationController, animated: true)
    }
    
    func popScreen() {
        navigationController?.popViewController(animated: true)
    }
    
    func openRecentlyWatchedVideos() {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: nodeRepository
        )
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let sensitiveNodeUseCase = SensitiveNodeUseCase(nodeRepository: nodeRepository, accountUseCase: accountUseCase)
        let nodeIconUseCase = NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: sdk))
        let recenltyOpenedNodesRepository = RecentlyOpenedNodesRepository(store: MEGAStore.shareInstance(), sdk: sdk)
        let recenltyOpenedNodeUseCase = RecentlyOpenedNodesUseCase(recentlyOpenedNodesRepository: recenltyOpenedNodesRepository)
        let viewController = RecentlyWatchedVideosViewController(
            videoConfig: .live(),
            recentlyOpenedNodesUseCase: recenltyOpenedNodeUseCase,
            sharedUIState: RecentlyWatchedVideosSharedUIState(),
            router: self,
            thumbnailLoader: VideoRevampFactory.makeThumbnailLoader(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeIconUseCase: nodeIconUseCase
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: DIContainer.featureFlagProvider
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> some View {
        let viewModel = EnforceCopyrightWarningViewModel(
            preferenceUseCase: PreferenceUseCase.default,
            copyrightUseCase: CopyrightUseCase(
                shareUseCase: ShareUseCase(
                    shareRepository: ShareRepository.newRepo,
                    filesSearchRepository: FilesSearchRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                )
            )
        )
        return EnforceCopyrightWarningView(viewModel: viewModel) {
            GetVideoPlaylistsLinksViewWrapper(videoPlaylist: videoPlaylist)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }
    }
    
    private func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
}

struct ShareEmptyView: View {
    var body: some View {
        Text("TBD")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
