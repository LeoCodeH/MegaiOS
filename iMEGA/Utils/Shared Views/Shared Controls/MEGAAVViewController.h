#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AVViewModel;

typedef NS_ENUM(NSInteger, MEGAAVViewControllerType) {
    // To avoid logical errors caused by mixing, the types of ViewController are distinguished here.
    MEGAAVViewControllerFile = 0, // Corresponding to the VC created by MEGAAVViewController(url:)
    MEGAAVViewControllerNode = 1, // Corresponding to the VC created by MEGAAVViewController(for:, folerLink:, apiForStreaming:)
};

@interface MEGAAVViewController : AVPlayerViewController

@property (nonatomic, strong, nonnull) AVViewModel *viewModel;
@property (nonatomic, strong, nonnull) UIActivityIndicatorView  *activityIndicator;
@property (nonatomic, assign) BOOL hasPlayedOnceBefore;
@property (nonatomic, assign) BOOL isEndPlaying;
@property (nonatomic, strong, nullable) MEGANode *node;
@property (nonatomic, strong, nullable) NSURL *fileUrl;
@property (nonatomic, strong, nullable) MEGASdk *apiForStreaming;
@property (nonatomic, assign) BOOL isFolderLink;
@property (nonatomic, assign, readonly) BOOL enablePreload; // Hard coded for easy testing. If there is a configuration center, it can be read from the configuration center.
@property (nonatomic, assign, readonly) MEGAAVViewControllerType vcType; // Indicate the type of ViewController

- (instancetype _Nonnull)initWithURL:(NSURL *_Nonnull)fileUrl;
- (instancetype _Nonnull)initWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming;
- (NSString *_Nullable)fileFingerprint;


- (BOOL)reuseWithURL:(NSURL * _Nonnull)fileUrl; // Reuse the ViewController of type 'MEGAAVViewControllerFile', and the data will be updated internally.
- (BOOL)reuseWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming; // Reuse the ViewController of type 'MEGAAVViewControllerNode', and the data will be updated internally.
- (void)asyncPreload; // Asynchronously preload relevant resources

@end
