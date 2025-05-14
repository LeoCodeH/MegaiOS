#import "MEGAAVViewController.h"

#import "LTHPasscodeViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

static const NSUInteger MIN_SECOND = 10; // Save only where the users were playing the file, if the streaming second is greater than this value.

@interface MEGAAVViewController () <AVPlayerViewControllerDelegate>

@property (nonatomic, assign, getter=isViewDidAppearFirstTime) BOOL viewDidAppearFirstTime;
@property (nonatomic, strong) NSMutableSet *subscriptions;

@property (nonatomic, strong, nullable) AVAsset *preloadAsset; // nil if 'self.enablePreload' is NO
@property (nonatomic, strong, nullable) AVPlayerItem *preloadPlayerItem; // nil if 'self.enablePreload' is NO

@end

@implementation MEGAAVViewController

- (instancetype)initWithURL:(NSURL *)fileUrl {
    self = [super init];
    
    if (self) {
        _enablePreload = YES; // Hard coded for easy testing. If there is a configuration center, it can be read from the configuration center.
        _vcType = MEGAAVViewControllerFile;
        self.viewModel = [self makeViewModel];
        MEGALogInfo(@"[MEGAAVViewController] init with url: %@", fileUrl);
        self.fileUrl    = fileUrl;
        self.node       = nil;
        _isFolderLink   = NO;
        _subscriptions = [[NSMutableSet alloc] init];
        _hasPlayedOnceBefore = NO;
    }
    
    return self;
}

- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk *)apiForStreaming {
    self = [super init];
    
    if (self) {
        _enablePreload = YES; // Hard coded for easy testing. If there is a configuration center, it can be read from the configuration center.
        _vcType = MEGAAVViewControllerNode;
        self.viewModel = [self makeViewModel];
        _apiForStreaming = apiForStreaming;
        self.node            = folderLink ? [MEGASdk.sharedFolderLink authorizeNode:node] : node;
        _isFolderLink        = folderLink;
        self.fileUrl         = [self streamingPathWithNode:node];
        MEGALogInfo(@"[MEGAAVViewController] init with node %@, is folderLink: %d, fileUrl: %@, apiForStreaming: %@", self.node, folderLink, self.fileUrl, apiForStreaming);
        _hasPlayedOnceBefore = NO;
    }
        
    return self;
}

- (BOOL)reuseWithURL:(NSURL * _Nonnull)fileUrl {
    if (self.vcType != MEGAAVViewControllerFile) {
        return NO;
    }
    
    // update internal data
    MEGALogInfo(@"[MEGAAVViewController] update with url: %@", fileUrl);
    if (self.player) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    self.preloadPlayerItem = nil;
    self.preloadAsset = nil;
    
    self.fileUrl    = fileUrl;
    self.node       = nil;
    _isFolderLink   = NO;
    _hasPlayedOnceBefore = NO;
    [self prepareBeforeViewAppear]; // viewDidLoad is called only once. Here, the common logic in viewDidLoad is encapsulated into another method to reuse.
    return YES;
}

- (BOOL)reuseWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming {
    if (self.vcType != MEGAAVViewControllerNode) {
        return NO;
    }
    
    // update internal data
    if (self.player) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    self.preloadPlayerItem = nil;
    self.preloadAsset = nil;
    
    _apiForStreaming = apiForStreaming;
    self.node            = folderLink ? [MEGASdk.sharedFolderLink authorizeNode:node] : node;
    _isFolderLink        = folderLink;
    self.fileUrl         = [self streamingPathWithNode:node];
    MEGALogInfo(@"[MEGAAVViewController] update with node %@, is folderLink: %d, fileUrl: %@, apiForStreaming: %@", self.node, folderLink, self.fileUrl, apiForStreaming);
    _hasPlayedOnceBefore = NO;
    [self prepareBeforeViewAppear]; // viewDidLoad is called only once. Here, the common logic in viewDidLoad is encapsulated into another method to reuse.
    return YES;
}

- (void)asyncPreload {
    if (!self.enablePreload ||
        self.preloadAsset ||
        self.preloadPlayerItem) {
        return;
    }
    
    BOOL needToCreatePlayer = (self.player == nil); // If the ViewController already holds the player, there is no need to create another one.
    NSURL *fileUrl = [self.fileUrl copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Load resources in the asynchronous queue
        AVAsset *asset = [AVAsset assetWithURL:fileUrl];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        AVPlayer *player = nil;
        if (needToCreatePlayer) {
            player = [AVPlayer playerWithPlayerItem:playerItem];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            // After the resource loading is completed, return to the main thread for saving.
            if (self.preloadAsset || self.preloadPlayerItem) {
                return;
            }
            
            self.preloadAsset = asset;
            self.preloadPlayerItem = playerItem;
            if (needToCreatePlayer && player) {
                self.player = player;
            }
            else {
                // For cases where the ViewController already holds a player, directly replace the player's item to further reduce overhead (there is a lot of logic inside setPlayer).
                [self.player replaceCurrentItemWithPlayerItem:playerItem];
            }
            [self.subscriptions addObject:[self bindPlayerItemStatusWithPlayerItem:playerItem]];
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareBeforeViewAppear]; // viewDidLoad is called only once. Here, the common logic in viewDidLoad is encapsulated into another method to reuse.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *fingerprint = [self fileFingerprint];

    if (self.isViewDidAppearFirstTime) {
        if (fingerprint && ![fingerprint isEqualToString:@""]) {
            MOMediaDestination *mediaDestination;
            if (self.node) {
                mediaDestination = [[MEGAStore shareInstance] fetchRecentlyOpenedNodeWithFingerprint:fingerprint].mediaDestination;
            } else {
                mediaDestination = [[MEGAStore shareInstance] fetchMediaDestinationWithFingerprint:fingerprint];
            }
            if (mediaDestination.destination.longLongValue > 0 && mediaDestination.timescale.intValue > 0) {
                if ([FileExtensionGroupOCWrapper verifyIsVideo:[self fileName]]) {
                    NSString *infoVideoDestination = LocalizedString(@"video.alert.resumeVideo.message", @"Message to show the user info (video name and time) about the resume of the video");
                    infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%1$s" withString:[self fileName]];
                    infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%2$s" withString:[self timeForMediaDestination:mediaDestination]];
                    UIAlertController *resumeOrRestartAlert = [UIAlertController alertControllerWithTitle:LocalizedString(@"video.alert.resumeVideo.title", @"Alert title shown for video with options to resume playing the video or start from the beginning") message:infoVideoDestination preferredStyle:UIAlertControllerStyleAlert];
                    [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"video.alert.resumeVideo.button.restart", @"Alert button title that will start playing the video from the beginning") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self seekToDestination:nil play:YES];
                    }]];
                    [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"video.alert.resumeVideo.button.resume", @"Alert button title that will resume playing the video") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self seekToDestination:mediaDestination play:YES];
                    }]];
                    [self presentViewController:resumeOrRestartAlert animated:YES completion:nil];
                } else {
                    [self seekToDestination:mediaDestination play:NO];
                }
            } else {
                [self seekToDestination:nil play:YES];
            }
        } else {
            [self seekToDestination:nil play:YES];
        }
    }
    
    [[AVPlayerManager shared] assignDelegateTo:self];
    
    self.viewDidAppearFirstTime = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([[AVPlayerManager shared] isPIPModeActiveFor:self]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self stopStreaming];

        if (![AudioPlayerManager.shared isPlayerAlive]) {
            [AudioSessionUseCaseOCWrapper.alloc.init configureDefaultAudioSession];
        }

        if ([AudioPlayerManager.shared isPlayerAlive]) {
            [AudioPlayerManager.shared audioInterruptionDidEndNeedToResume:YES];
        }
    });
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_presentingViewController.view
                                                     withAnimation:YES
                                                        withLogout:YES
                                                    andLogoutTitle:LocalizedString(@"logoutLabel", @"")];
    }
    
    [self deallocPlayer];
    [self cancelPlayerProcess];
    self.player = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([[AVPlayerManager shared] isPIPModeActiveFor:self]) {
        return;
    }

    CMTime mediaTime = CMTimeMake(self.player.currentTime.value, self.player.currentTime.timescale);
    Float64 second = CMTimeGetSeconds(mediaTime);
    
    NSString *fingerprint = [self fileFingerprint];
    
    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        if (self.isEndPlaying || second <= MIN_SECOND) {
            [[MEGAStore shareInstance] deleteMediaDestinationWithFingerprint:fingerprint];
            [self saveRecentlyWatchedVideoWithDestination:[NSNumber numberWithInt:0]
                                                timescale:nil];
        } else {
            if (self.node) {
                [self saveRecentlyWatchedVideoWithDestination:[NSNumber numberWithLongLong:self.player.currentTime.value]
                                                    timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
            } else {
                [[MEGAStore shareInstance] insertOrUpdateMediaDestinationWithFingerprint:fingerprint destination:[NSNumber numberWithLongLong:self.player.currentTime.value] timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
            }
        }
    }
}

#pragma mark - Private

- (void)seekToDestination:(MOMediaDestination *)mediaDestination play:(BOOL)play {
    if (!self.fileUrl) {
        return;
    }

    [self willStartPlayer];
    
    // Adapt the logic for enabling and disabling the preloading capability.
    AVAsset *asset = nil;
    if (self.enablePreload) {
        if (self.preloadAsset) {
            asset = self.preloadAsset;
        }
        else {
            asset = [AVAsset assetWithURL:self.fileUrl];
            self.preloadAsset = asset;
        }
    }
    else {
        asset = [AVAsset assetWithURL:self.fileUrl];
    }

    // Adapt the logic for enabling and disabling the preloading capability.
    AVPlayerItem *playerItem = nil;
    if (self.enablePreload) {
        if (self.preloadPlayerItem) {
            playerItem = self.preloadPlayerItem;
        }
        else {
            playerItem = [AVPlayerItem playerItemWithAsset:asset];
            self.preloadPlayerItem = playerItem;
        }
    }
    else {
        playerItem = [AVPlayerItem playerItemWithAsset:asset];
    }

    [self setPlayerItemMetadataWithPlayerItem:playerItem node:self.node];
    
    if (!self.player) {
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];;
        self.player = player;
        [self.subscriptions addObject:[self bindPlayerItemStatusWithPlayerItem:playerItem]];
    }

    [self seekToMediaDestination:mediaDestination];
    
    if (play) {
        [self.player play];
    }
    
    [self.subscriptions addObject:[self bindPlayerTimeControlStatus]];
}

- (void)replayVideo {
    if (self.player) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        self.isEndPlaying = NO;
    }
}

- (void)stopStreaming {
    if (self.node) {
        [self.apiForStreaming httpServerStop];
    }
}

- (NSString *)timeForMediaDestination:(MOMediaDestination *)mediaDestination {
    CMTime mediaTime = CMTimeMake(mediaDestination.destination.longLongValue, mediaDestination.timescale.intValue);
    NSTimeInterval durationSeconds = (NSTimeInterval)CMTimeGetSeconds(mediaTime);
    return [NSString mnz_stringFromTimeInterval:durationSeconds];
}

- (NSString *)fileName {
    if (self.node) {
        return self.node.name;
    } else {
        return self.fileUrl.lastPathComponent;
    }
}

- (NSString *)fileFingerprint {
    NSString *fingerprint;

    if (self.node) {
        MEGALogInfo(@"[MEGAAVViewController] Getting fileFingerprint from node %@", self.node);
        fingerprint = self.node.fingerprint;
    } else {
        fingerprint = [MEGASdk.shared fingerprintForFilePath:self.fileUrl.path];
        MEGALogInfo(@"[MEGAAVViewController] Getting fileFingerprint from sdk with result %@", fingerprint);
    }
    
    return fingerprint;
}

#pragma mark - Private method
- (void)prepareBeforeViewAppear __attribute__((objc_direct)) {
    // viewDidLoad is called only once. Here, the common logic in viewDidLoad is encapsulated into another method to reuse.
    [self.viewModel onViewDidLoad];
    [self checkIsFileViolatesTermsOfService];
    [AudioSessionUseCaseOCWrapper.alloc.init configureVideoAudioSession];
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidStart];
    }

    self.viewDidAppearFirstTime = YES;
    
    self.subscriptions = [self bindToSubscriptionsWithMovieStalled:^{
        [self movieStalledCallback];
    }];
    
    [self configureActivityIndicator];
    
    [self configureViewColor];
}

@end
