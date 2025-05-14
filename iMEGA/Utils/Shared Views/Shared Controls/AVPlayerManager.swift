import AVKit
import Combine
import Foundation

@objc protocol AVPlayerManagerProtocol {
    
    ///  Creates a new AVPlayerViewController for the given node or return the current active AVPlayerViewController that is currently playing in Picture in Picture mode.
    /// - Parameters:
    ///   - node: MegaNode
    ///   - folderLink: Bool
    ///   - sdk: MegaSDK used for streaming the node
    /// - Returns: Creates or returns active AVPlayerViewcontroller
    func makePlayerController(for node: MEGANode, folderLink: Bool, sdk: MEGASdk) -> AVPlayerViewController
    
    ///  Creates a new AVPlayerViewController for the given node or return the current active AVPlayerViewController that is currently playing in Picture in Picture mode.
    /// - Parameters:
    ///   - url: URL
    /// - Returns: Creates or returns active AVPlayerViewcontroller
    func makePlayerController(for url: URL) -> AVPlayerViewController
    
    /// Call this to assign the passed AVPlayerViewController to this manager
    /// - Parameter to:AVPlayerViewController that will set its delegate to this manager
    func assignDelegate(to: AVPlayerViewController)

    /// Determines if the given controller is currently in Picture in Picture mode
    /// - Parameter controller: AVPlayerViewController
    /// - Returns: True if in PIP Mode, else false
    func isPIPModeActive(for controller: AVPlayerViewController) -> Bool
}

@objc final class AVPlayerManager: NSObject, AVPlayerManagerProtocol {
    
    // Public Shared Manager
    @objc static let shared: any AVPlayerManagerProtocol = AVPlayerManager(sdk: MEGASdk.shared)
    
    private let sdk: MEGASdk
    private weak var activeVideoViewController: MEGAAVViewController?
    
    private let enableReusePlayerController: Bool = true // Hard coded for easy testing. If there is a configuration center in production, it can be read from the configuration center.
    private var playerControllerCache: NSCache<NSString, MEGAAVViewController>? // nil if 'enableReusePlayerController' is false. Key is a NSString type of 'PlayerControllerCacheKey'
    
    enum PlayerControllerCacheKey: String {
        // To avoid logical errors caused by mixing, the types of ViewController are distinguished here.
        case file // Corresponding to the VC created by MEGAAVViewController(url:)
        case node // Corresponding to the VC created by MEGAAVViewController(for:, folerLink:, apiForStreaming:)
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        if self.enableReusePlayerController {
            self.playerControllerCache = NSCache<NSString, MEGAAVViewController>()
        }
    }
    
    func makePlayerController(for node: MEGANode, folderLink: Bool, sdk: MEGASdk) -> AVPlayerViewController {
        
        guard let activeVideoViewController,
              activeVideoViewController.fileFingerprint() == node.fingerprint else {
            
            // Give priority to using the cache of the same type of ViewController. If it doesn't exist, create one.
            var vc = queryCachePlayerController(for: node, folderLink: folderLink, apiForStreaming: sdk)
            if vc == nil {
                vc = MEGAAVViewController(node: node, folderLink: folderLink, apiForStreaming: sdk)
            }
            if vc!.enablePreload {
                vc!.asyncPreload() // Asynchronously preload relevant resources
            }
            return vc!
        }
        
        return activeVideoViewController
    }
    
    func makePlayerController(for url: URL) -> AVPlayerViewController {
        guard let activeVideoViewController,
              activeVideoViewController.fileFingerprint() == sdk.fingerprint(forFilePath: url.path) else {
            
            // Give priority to using the cache of the same type of ViewController. If it doesn't exist, create one.
            var vc = queryCachePlayerController(for: url)
            if vc == nil {
                vc = MEGAAVViewController(url: url)
            }
            if vc!.enablePreload {
                vc!.asyncPreload() // Asynchronously preload relevant resources
            }
            return vc!
        }
        return activeVideoViewController
    }
    
    func assignDelegate(to: AVPlayerViewController) {
        to.delegate = self
    }
    
    func isPIPModeActive(for controller: AVPlayerViewController) -> Bool {
        controller == activeVideoViewController
    }
    
    private func queryCachePlayerController(for node: MEGANode, folderLink: Bool, apiForStreaming: MEGASdk) -> MEGAAVViewController? {
        // If there is a cache of the same type of ViewController, retrieve it from the cache for reuse.
        guard enableReusePlayerController,
              let cache = playerControllerCache,
              let vc = cache.object(forKey: PlayerControllerCacheKey.node.rawValue as NSString) else {
            return nil
        }
        
        cache.removeObject(forKey: PlayerControllerCacheKey.node.rawValue as NSString)
        // Update the internal data of the ViewController
        return vc.reuse(with: node, folderLink: folderLink, apiForStreaming: sdk) ? vc : nil
    }
    
    private func queryCachePlayerController(for url: URL) -> MEGAAVViewController? {
        // If there is a cache of the same type of ViewController, retrieve it from the cache for reuse.
        guard enableReusePlayerController,
              let cache = playerControllerCache,
              let vc = cache.object(forKey: PlayerControllerCacheKey.file.rawValue as NSString) else {
            return nil
        }
        
        cache.removeObject(forKey: PlayerControllerCacheKey.file.rawValue as NSString)
         // Update the internal data of the ViewController
        return vc.reuse(with: url) ? vc : nil
    }
}

// MARK: AVPlayerViewControllerDelegate
extension AVPlayerManager: AVPlayerViewControllerDelegate {
        
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        guard playerViewController.presentingViewController == nil else {
            completionHandler(true)
            return
        }
        
        UIApplication.mnz_presentingViewController().present(playerViewController, animated: true)

        completionHandler(true)
    }
        
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool { false }
    
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        activeVideoViewController = playerViewController as? MEGAAVViewController
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        activeVideoViewController = nil
    }
    
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
        // When the ViewController exits, put it back into the corresponding cache.
        guard enableReusePlayerController,
              let cache = playerControllerCache,
              let megaVC = playerViewController as? MEGAAVViewController else {
            return
        }
        
        switch megaVC.vcType {
        case .file:
            cache.setObject(megaVC, forKey: PlayerControllerCacheKey.file.rawValue as NSString)
        case .node:
            cache.setObject(megaVC, forKey: PlayerControllerCacheKey.node.rawValue as NSString)
        default:
            return
        }
    }
}
