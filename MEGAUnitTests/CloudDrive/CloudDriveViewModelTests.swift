import AsyncAlgorithms
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGASwift
import MEGATest
import XCTest

class CloudDriveViewModelTests: XCTestCase {
    
    @MainActor
    func testUpdateEditModeActive_changeActiveToTrueWhenCurrentlyActive_shouldInvokeOnlyOnce() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(true))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode])
    }
    
    @MainActor
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyNotActive_shouldInvokeNotInvoke() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(false))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [])
    }
    
    @MainActor
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyActive_shouldInvokeEnterAndExitCommands() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode, .exitSelectionMode])
    }
    
    @MainActor
    func testShouldShowMediaDiscoveryAutomatically_containsNonMediaFiles_shouldReturnFalse() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: true])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.pdf"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    @MainActor
    func testShouldShowMediaDiscoveryAutomatically_containsOnlyMediaFiles_shouldReturnTrue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: true])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.mp4"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertTrue(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    @MainActor
    func testShouldShowMediaDiscoveryAutomatically_preferenceOff_shouldReturnFalse() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: false])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    @MainActor
    func testHasMediaFiles_nodesContainVisualMediaFile_shouldReturnTrue() {
        let sut = makeSUT()
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.mp4"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertTrue(sut.hasMediaFiles(nodes: nodes))
    }
    
    @MainActor
    func testHasMediaFiles_nodesDoesNotContainVisualMediaFile_shouldReturnFalse() {
        let sut = makeSUT()
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.pdf"),
                                         MockNode(handle: 2, name: "test.docx")])
        XCTAssertFalse(sut.hasMediaFiles(nodes: nodes))
    }
    
    @MainActor
    func testSortOrder_whereViewModeIsMediaDiscovery_shouldReturnEitherNewestOrOldest() throws {
        
        let expectations: [(SortOrderEntity, SortOrderType)] = [
            (.defaultAsc, .newest),
            (.modificationAsc, .oldest),
            (.modificationDesc, .newest),
            (.favouriteDesc, .newest),
            (.favouriteAsc, .newest)
        ]
        
        expectations.forEach { (arrangement, expect) in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: arrangement))
            // Act
            let result = sut.sortOrder(for: .mediaDiscovery)
            XCTAssertEqual(result, expect, "Given SortOrderEntity \(arrangement)")
        }
    }
    
    @MainActor
    func testSortOrder_whereViewModeIsList_shouldReturnMatchingSortOrder() throws {
        
        SortOrderEntity.allCases.forEach { sortOrder in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: sortOrder))
            // Act
            let result = sut.sortOrder(for: .list)
            // Assert
            XCTAssertEqual(result, sortOrder.toSortOrderType(), "Given SortOrderEntity \(sortOrder)")
        }
    }
    
    @MainActor
    func testSortOrder_whereViewModeIsThumbnail_shouldReturnMatchingSortOrder() throws {
        
        SortOrderEntity.allCases.forEach { sortOrder in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: sortOrder))
            // Act
            let result = sut.sortOrder(for: .thumbnail)
            // Assert
            XCTAssertEqual(result, sortOrder.toSortOrderType(), "Given SortOrderEntity \(sortOrder)")
        }
    }
    
    @MainActor
    func testSortOrder_whereViewModeIsPerFolder_shouldReturnMatchingSortOrder() throws {
        
        SortOrderEntity.allCases.forEach { sortOrder in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: sortOrder))
            // Act
            let result = sut.sortOrder(for: .perFolder)
            // Assert
            XCTAssertEqual(result, sortOrder.toSortOrderType(), "Given SortOrderEntity \(sortOrder)")
        }
    }
    
    @MainActor
    func testShouldShowConfirmationAlertForRemovedFiles() {
        let sut = makeSUT()
        
        let inputs: [(fileCount: Int, folderCount: Int)] = [
            (0, 0),
            (1, 0),
            (0, 1),
            (1, 1)
        ]
        
        let expected: [Bool] = [false, true, true, true]
        
        let outputs = inputs.map {
            sut.shouldShowConfirmationAlert(forRemovedFiles: $0.fileCount, andFolders: $0.folderCount)
        }
        
        XCTAssertEqual(outputs, expected)
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_hiddenNodesFeatureOff_shouldReturnNil() async {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
        let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        XCTAssertNil(isHidden)
    }
    
    @MainActor
    func tesIsParentMarkedAsSensitiveForDisplayMode_displayModeNotCloudDrive_shouldReturnNil() async {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let parentNode = MockNode(handle: 1)
        let sut = makeSUT(parentNode: parentNode,
                          remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .rubbishBin, isFromSharedItem: false)
        XCTAssertNil(isHidden)
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_displayModeCloudDriveIsFile_shouldReturnNil() async {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let parentNode = MockNode(handle: 1, nodeType: .file)
        let sut = makeSUT(parentNode: parentNode,
                          remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        XCTAssertNil(isHidden)
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_rootNode_shouldReturnNil() async {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let parentNode = MockNode(handle: 1, nodeType: .root)
        let sut = makeSUT(parentNode: parentNode,
                          remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        XCTAssertNil(isHidden)
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_parentInheritsSensitivity_shouldReturnNil() async {
        let parentNode = MockNode(handle: 1, nodeType: .folder)
        let sut = makeSUT(parentNode: parentNode,
                          accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
                          remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        XCTAssertNil(isHidden)
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_displayModeCloudDriveIsFolder_shouldMatchSensitiveState() async throws {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let nodeSensitiveChecker = NodeSensitivityChecker(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(false))
        )
        for await isMarkedSensitive in [true, false].async {
            let parentNode = MockNode(handle: 1, nodeType: .folder, isMarkedSensitive: isMarkedSensitive)
            let sut = makeSUT(parentNode: parentNode,
                              accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
                              remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
                              nodeSensitivityChecker: nodeSensitiveChecker)

            let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
            XCTAssertEqual(isHidden, isMarkedSensitive)
        }
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_whenEntryPointArrivedFromSharedItem_shouldReturnNilForDisplaySharedItems() async throws {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        for await isMarkedSensitive in [true, false].async {
            let parentNode = MockNode(handle: 1, nodeType: .folder, isMarkedSensitive: isMarkedSensitive)
            let sut = makeSUT(parentNode: parentNode,
                              remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: true)
            XCTAssertNil(isHidden)
        }
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_systemNode_shouldReturnNil() async throws {
        let parentNode = MockNode(handle: 1, nodeType: .folder, isMarkedSensitive: false)
        let sut = makeSUT(
            parentNode: parentNode,
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(
                nodesForLocation: [.cameraUpload: parentNode.toNodeEntity()]),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        XCTAssertNil(isHidden)
    }
    
    @MainActor
    func testIsParentMarkedAsSensitiveForDisplayMode_accountNotValid_shouldReturnFalse() async throws {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let parentNode = MockNode(handle: 1, nodeType: .folder, isMarkedSensitive: true)
        let nodeSensitiveChecker = NodeSensitivityChecker(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false)
        )
        let sut = makeSUT(
            parentNode: parentNode,
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: false),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            nodeSensitivityChecker: nodeSensitiveChecker)

        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        
        XCTAssertFalse(try XCTUnwrap(isHidden))
    }
    
    @MainActor
    func testAction_updateParentNode_updatesParentNodeAndReloadsNavigationBarItems() async throws {
        let updatedParentNode = MockNode(handle: 1, nodeType: .folder, isMarkedSensitive: true)
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let nodeSensitiveChecker = NodeSensitivityChecker(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(false))
        )
        let sut = makeSUT(parentNode: MockNode(handle: 1, nodeType: .folder, isMarkedSensitive: false),
                          accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
                          remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
                          nodeSensitivityChecker: nodeSensitiveChecker)

        await test(viewModel: sut, action: .updateParentNode(updatedParentNode),
             expectedCommands: [.reloadNavigationBarItems])
        
        let isHidden = await sut.isParentMarkedAsSensitive(forDisplayMode: .cloudDrive, isFromSharedItem: false)
        XCTAssertTrue(try XCTUnwrap(isHidden))
    }
    
    @MainActor
    func testAction_moveNodeToRubbishBin_handledByMoveToRubbishBinViewModel() throws {
        // given
        let node = MockNode(handle: 1)
        let action: CloudDriveViewModel.Action = .moveToRubbishBin([node])
        let moveToRubbishBinViewModel = MockMoveToRubbishBinViewModel()
        let sut = makeSUT(moveToRubbishBinViewModel: moveToRubbishBinViewModel)
        
        // when
        sut.dispatch(action)
        
        // then
        let updatedNode = try XCTUnwrap(moveToRubbishBinViewModel.calledNodes.first)
        XCTAssertEqual(updatedNode.handle, 1)
    }
    
    @MainActor
    func testShouldExcludeSensitiveItems_featureFlagOff_shouldReturnFalse() async {
        let sut = makeSUT(remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]))
        
        let shouldExclude = await sut.shouldExcludeSensitiveItems()
        XCTAssertFalse(shouldExclude)
    }
    
    @MainActor
    func testShouldExcludeSensitiveItems_called_shouldReturnInverseOfShowHiddenNodes() async {
        for await excludeSensitives in [true, false].async {
            let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
                excludeSensitives: excludeSensitives)
            let sut = makeSUT(
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
            
            let shouldExclude = await sut.shouldExcludeSensitiveItems()
            XCTAssertEqual(shouldExclude, excludeSensitives)
        }
    }
    
    @MainActor
    func testDispatchAction_updateSensitivitySettingOnNextSearch_shouldRecalculateSensitiveSetting() async throws {
        let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
            excludeSensitives: true)
        let sut = makeSUT(
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
        
        let shouldExcludeFirstCall = await sut.shouldExcludeSensitiveItems()
        XCTAssertTrue(shouldExcludeFirstCall)

        sensitiveDisplayPreferenceUseCase.$excludeSensitives.mutate { $0 = false }
        sut.dispatch(.resetSensitivitySetting)
        
        let shouldExcludeSecondCall = await sut.shouldExcludeSensitiveItems()
        XCTAssertFalse(shouldExcludeSecondCall)
    }
    
    @MainActor
    func test_didTapChooseFromPhotos_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapChooseFromPhotos,
            expectedEvent: CloudDriveChooseFromPhotosMenuToolbarEvent()
        )
    }

    @MainActor
    func test_didTapImportFromFiles_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapImportFromFiles,
            expectedEvent: CloudDriveImportFromFilesMenuToolbarEvent()
        )
    }
    
    @MainActor
    func test_didTapNewFolder_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapNewFolder,
            expectedEvent: CloudDriveNewFolderMenuToolbarEvent()
        )
    }
    
    @MainActor
    func test_didTapNewTextFile_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapNewTextFile,
            expectedEvent: CloudDriveNewTextFileMenuToolbarEvent()
        )
    }

    @MainActor
    func test_didOpenAddMenu_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didOpenAddMenu,
            expectedEvent: CloudDriveAddMenuEvent()
        )
    }
    
    @MainActor
    func tests_didTapHideNodes_trackAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapHideNodes,
            expectedEvent: CloudDriveHideNodeMenuItemEvent())
    }
    
    @MainActor
    func testNodesForDisplayMode_cloudDrive_shouldUseCorrectFilterForNonRecursiveSearch() async {
        let parentNode = MockNode(handle: 89)
        let expectedNodes = [MockNode(handle: 1), MockNode(handle: 3)]
        let rootNode = MockNode(handle: 1)
        let sdk = MockSdk(nodes: expectedNodes, megaRootNode: rootNode)
        let sut = makeSUT(parentNode: parentNode,
                          sdk: sdk)
        
        let nodes = await sut.nodesForDisplayMode(.cloudDrive, sortOrder: .none)
        
        XCTAssertEqual(nodes?.toNodeArray(), expectedNodes)
        let searchQuery = sdk.searchQueryParameters
        XCTAssertEqual(searchQuery?.node.handle, parentNode.handle)
        XCTAssertEqual(searchQuery?.sensitiveFilter, .disabled)
    }
    
    @MainActor
    func testNodesForDisplayMode_nilParent_shouldReturnNil() async {
        let sut = makeSUT(parentNode: nil)
        
        let nodes = await sut.nodesForDisplayMode(.cloudDrive, sortOrder: .none)
        
        XCTAssertNil(nodes)
    }
    
    @MainActor
    func testNodesForDisplayMode_cloudDriveParentProvidedSensitiveSettinOn_shouldUseCorrectFilterForNonRecursiveSearch() async {
        let expectedNodes = [MockNode(handle: 1), MockNode(handle: 3)]
        let sdk = MockSdk(nodes: expectedNodes)
        
        let testCases = [(showHiddenNodes: true, expectedSensitiveFilter: MEGASearchFilterSensitiveOption.nonSensitiveOnly),
                         (showHiddenNodes: false, expectedSensitiveFilter: MEGASearchFilterSensitiveOption.disabled)]
        
        for (excludeSensitives, expectedFilter) in testCases {
            let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
                excludeSensitives: excludeSensitives)
            
            let parentNode = MockNode(handle: 89)
            let sut = makeSUT(parentNode: parentNode,
                              sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                              sdk: sdk)
            
            let nodes = await sut.nodesForDisplayMode(.cloudDrive, sortOrder: .none)
            
            XCTAssertEqual(nodes?.toNodeArray(), expectedNodes)
            let searchQuery = sdk.searchQueryParameters
            XCTAssertEqual(searchQuery?.node.handle, parentNode.handle)
            XCTAssertEqual(searchQuery?.sensitiveFilter, expectedFilter)
        }
    }
    
    @MainActor
    func testNodesForDisplayMode_rubbishBinAndBackup_shouldDisableSensitiveSearch() async {
        let expectedNodes = [MockNode(handle: 1), MockNode(handle: 3)]
        let sdk = MockSdk(nodes: expectedNodes)
        
        for displayMode in [DisplayMode.rubbishBin, .backup] {
            let parentNode = MockNode(handle: 89)
            let sut = makeSUT(parentNode: parentNode,
                              sdk: sdk)
            
            let nodes = await sut.nodesForDisplayMode(displayMode, sortOrder: .none)
            
            XCTAssertEqual(nodes?.toNodeArray(), expectedNodes)
            let searchQuery = sdk.searchQueryParameters
            XCTAssertEqual(searchQuery?.node.handle, parentNode.handle)
            XCTAssertEqual(searchQuery?.sensitiveFilter, .disabled)
        }
    }
    
    @MainActor
    func testNodesForDisplayMode_invalidDisplayMode_returnsNil() async {
        for displayMode in [DisplayMode.sharedItem, .nodeInfo, .nodeVersions, .folderLink, .fileLink, .nodeInsideFolderLink,
                            .recents, .publicLinkTransfers, .transfers, .transfersFailed, .chatAttachment, .chatSharedFiles,
                            .previewDocument, .textEditor, .mediaDiscovery, .photosFavouriteAlbum, .photosAlbum,
                            .photosTimeline, .previewPdfPage, .albumLink] {
            let sut = makeSUT(parentNode: MockNode(handle: 89))
            
            let nodes = await sut.nodesForDisplayMode(displayMode, sortOrder: .none)
            
            XCTAssertNil(nodes, "Expected nil nodes for display mode \(displayMode)")
        }
    }

    @MainActor
    func testIsParentMarkedAsSensitive_whenNodeIsSensitive_shouldMatchResults() async {
        await assertIsParentMarkedAsSensitive(
            isNodeSensitive: true,
            expectedDisplayMode: .cloudDrive,
            expectedIsFromSharedItem: false
        )
    }

    @MainActor
    func testIsParentMarkedAsSensitive_whenNodeIsNotSensitive_shouldMatchResults() async {
        await assertIsParentMarkedAsSensitive(
            isNodeSensitive: false,
            expectedDisplayMode: .backup,
            expectedIsFromSharedItem: true
        )
    }

    @MainActor
    func testIsParentMarkedAsSensitive_whenNodeDoesNotContainSenstivityInfo_shouldMatchResults() async {
        await assertIsParentMarkedAsSensitive(
            isNodeSensitive: nil,
            expectedDisplayMode: .sharedItem,
            expectedIsFromSharedItem: true
        )
    }

    @MainActor
    func makeSUT(
        parentNode: MEGANode? = MockNode(handle: 1),
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [:]),
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        tracker: some AnalyticsTracking = MockTracker(),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol = MockMoveToRubbishBinViewModel(),
        sdk: MEGASdk = MockSdk(),
        nodeSensitivityChecker: some NodeSensitivityChecking = NodeSensitivityChecker(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(),
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase()
        ),
        file: StaticString = #file,
        line: UInt = #line
    ) -> CloudDriveViewModel {
        let sut = CloudDriveViewModel(
            parentNode: parentNode,
            shareUseCase: shareUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            preferenceUseCase: preferenceUseCase, 
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            accountUseCase: accountUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            tracker: tracker,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            moveToRubbishBinViewModel: moveToRubbishBinViewModel,
            nodeSensitivityChecker: nodeSensitivityChecker,
            sdk: sdk
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    @MainActor
    private func trackAnalyticsEventTest(
        action: CloudDriveAction,
        expectedEvent: some EventIdentifier,
        file: StaticString = #file, 
        line: UInt = #line
    ) {
        let mockTracker = MockTracker()
        let sut = makeSUT(tracker: mockTracker)
        
        sut.dispatch(action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent],
            file: file,
            line: line
        )
    }
    
    private func makeSearchFilter(parentNodeHandle: MEGAHandle, excludeSensitive: Bool) -> MEGASearchFilter {
        MEGASearchFilter(
            term: "",
            parentNodeHandle: parentNodeHandle,
            nodeType: .unknown,
            category: .unknown,
            sensitiveFilter: excludeSensitive ? MEGASearchFilterSensitiveOption.nonSensitiveOnly : .disabled,
            favouriteFilter: .disabled,
            creationTimeFrame: nil,
            modificationTimeFrame: nil
        )
    }

    @MainActor
    private func assertIsParentMarkedAsSensitive(
        isNodeSensitive: Bool?,
        expectedDisplayMode: DisplayMode,
        expectedIsFromSharedItem: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let nodeSensitivityChecker = MockNodeSensitivityChecker(isSensitive: isNodeSensitive)
        let node = MockNode(handle: 100)
        let sut = makeSUT(parentNode: node, nodeSensitivityChecker: nodeSensitivityChecker)
        let result = await sut.isParentMarkedAsSensitive(
            forDisplayMode: expectedDisplayMode,
            isFromSharedItem: expectedIsFromSharedItem
        )

        XCTAssertEqual(result, isNodeSensitive, file: file, line: line)
        XCTAssertEqual(nodeSensitivityChecker.actions.count, 1, file: file, line: line)

        guard case let .evaluateNodeSensitivity(nodeSource, displayMode, isFromSharedItem)
                = nodeSensitivityChecker.actions.first else {
            XCTFail("action does not match", file: file, line: line)
            return
        }

        XCTAssertEqual(nodeSource.parentNode?.handle, node.handle, file: file, line: line)
        XCTAssertEqual(displayMode, expectedDisplayMode, file: file, line: line)
        XCTAssertEqual(isFromSharedItem, expectedIsFromSharedItem, file: file, line: line)
    }
}

final class MockNodeSensitivityChecker: NodeSensitivityChecking, @unchecked Sendable {
    enum Action {
        case evaluateNodeSensitivity(source: NodeSource, displayMode: DisplayMode, isFromSharedItem: Bool)
    }

    @Atomic var actions: [Action] = []
    private let isSensitive: Bool?

    init(isSensitive: Bool? = nil) {
        self.isSensitive = isSensitive
    }

    func evaluateNodeSensitivity(
        for nodeSource: NodeSource,
        displayMode: DisplayMode,
        isFromSharedItem: Bool
    ) async -> Bool? {
        $actions.mutate {
            $0.append(
                .evaluateNodeSensitivity(
                    source: nodeSource,
                    displayMode: displayMode,
                    isFromSharedItem: isFromSharedItem
                )
            )
        }
        return isSensitive
    }
}
