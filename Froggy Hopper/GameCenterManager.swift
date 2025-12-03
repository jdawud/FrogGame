import Foundation
import GameKit
import UIKit

/// Manages Game Center authentication, leaderboards, and score reporting
final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    
    // MARK: - Properties
    
    /// Your leaderboard ID from App Store Connect
    private let leaderboardIdentifier = "FroggyFeedLeaderboard01"
    
    /// Whether the local player is authenticated with Game Center
    var isAuthenticated: Bool {
        return GKLocalPlayer.local.isAuthenticated
    }
    
    /// Pending action to execute after successful authentication
    private var pendingAction: (() -> Void)?
    
    /// Reference to the presenting view controller for auth UI
    private weak var authPresentingViewController: UIViewController?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Authentication
    
    /// Call this ONCE at app launch from your root view controller
    /// - Parameter viewController: The view controller to present Game Center login UI from
    func authenticate(from viewController: UIViewController) {
        authPresentingViewController = viewController
        
        GKLocalPlayer.local.authenticateHandler = { [weak self] authViewController, error in
            DispatchQueue.main.async {
                self?.handleAuthentication(authViewController: authViewController, error: error)
            }
        }
    }
    
    /// Handles the authentication callback from Game Center
    private func handleAuthentication(authViewController: UIViewController?, error: Error?) {
        if let authVC = authViewController {
            // 🔐 Game Center wants to show login UI - present it
            print("🎮 Presenting Game Center login UI")
            if let presenter = authPresentingViewController ?? topViewController() {
                presenter.present(authVC, animated: true)
            }
        } else if GKLocalPlayer.local.isAuthenticated {
            // ✅ Successfully authenticated
            print("✅ Game Center authenticated: \(GKLocalPlayer.local.displayName)")
            
            // Show the Game Center access point (optional floating button)
            GKAccessPoint.shared.location = .topLeading
            GKAccessPoint.shared.isActive = true
            
            // Execute any pending action (like showing leaderboard)
            pendingAction?()
            pendingAction = nil
        } else {
            // ❌ Authentication failed or Game Center not available
            if let error = error {
                print("❌ Game Center auth failed: \(error.localizedDescription)")
            } else {
                print("⚠️ Game Center not available or user not signed in")
            }
        }
    }
    
    // MARK: - Leaderboard
    
    /// Presents the Game Center leaderboard UI
    /// - Parameter viewController: The view controller to present from
    func showLeaderboard(from viewController: UIViewController) {
        guard isAuthenticated else {
            // Not authenticated - show alert directing user to Settings
            showNotAuthenticatedAlert(from: viewController)
            return
        }
        
        print("🏆 Presenting leaderboard: \(leaderboardIdentifier)")
        
        let gcViewController = GKGameCenterViewController(
            leaderboardID: leaderboardIdentifier,
            playerScope: .global,
            timeScope: .allTime
        )
        gcViewController.gameCenterDelegate = self
        viewController.present(gcViewController, animated: true)
    }
    
    /// Shows an alert when user isn't signed into Game Center
    private func showNotAuthenticatedAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Game Center Required",
            message: "Please sign in to Game Center in Settings to view the leaderboard.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Score Reporting
    
    /// Reports a score to the leaderboard
    /// - Parameters:
    ///   - score: The player's score to submit
    ///   - completion: Optional completion handler with success/failure
    func reportScore(_ score: Int, completion: ((Bool) -> Void)? = nil) {
        guard isAuthenticated else {
            print("⚠️ Cannot report score - not authenticated")
            completion?(false)
            return
        }
        
        print("📊 Reporting score: \(score)")
        
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardIdentifier]
        ) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to report score: \(error.localizedDescription)")
                    completion?(false)
                } else {
                    print("✅ Score reported successfully: \(score)")
                    completion?(true)
                }
            }
        }
    }
    
    // MARK: - Achievements
    
    /// Achievement IDs - must match App Store Connect
    struct AchievementID {
        static let level1Complete = "Level_1"
        static let level2Complete = "Level_2"
        static let level3Complete = "Level_3"
        static let level4Complete = "Level_4"
        static let level5Complete = "Level_5"
        static let level6Complete = "Level_6"
        static let level7Complete = "Level_7"
        static let level8Complete = "Level_8"
        static let level9Complete = "Level_9"
        static let level10Complete = "Level_10"
        static let gameComplete = "Game_Complete"
        
        /// Returns the achievement ID for a given level
        static func forLevel(_ level: Int) -> String? {
            switch level {
            case 1: return level1Complete
            case 2: return level2Complete
            case 3: return level3Complete
            case 4: return level4Complete
            case 5: return level5Complete
            case 6: return level6Complete
            case 7: return level7Complete
            case 8: return level8Complete
            case 9: return level9Complete
            case 10: return level10Complete
            default: return nil
            }
        }
    }
    
    /// Reports a level completion achievement
    /// - Parameters:
    ///   - level: The level that was completed (1-10)
    ///   - completion: Optional completion handler
    func reportLevelComplete(_ level: Int, completion: ((Bool) -> Void)? = nil) {
        guard isAuthenticated else {
            print("⚠️ Cannot report achievement - not authenticated")
            completion?(false)
            return
        }
        
        guard let achievementID = AchievementID.forLevel(level) else {
            print("⚠️ No achievement ID for level \(level)")
            completion?(false)
            return
        }
        
        print("🏅 Reporting achievement: Level \(level) complete")
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = 100.0
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to report achievement: \(error.localizedDescription)")
                    completion?(false)
                } else {
                    print("✅ Achievement reported: Level \(level) complete!")
                    completion?(true)
                }
            }
        }
    }
    
    /// Reports the game completion achievement (all 10 levels done)
    func reportGameComplete(completion: ((Bool) -> Void)? = nil) {
        guard isAuthenticated else {
            print("⚠️ Cannot report achievement - not authenticated")
            completion?(false)
            return
        }
        
        print("🎮 Reporting achievement: Game Complete!")
        
        let achievement = GKAchievement(identifier: AchievementID.gameComplete)
        achievement.percentComplete = 100.0
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to report game complete: \(error.localizedDescription)")
                    completion?(false)
                } else {
                    print("✅ Game Complete achievement reported!")
                    completion?(true)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = baseVC?.presentedViewController {
            return topViewController(base: presented)
        }
        return baseVC
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
