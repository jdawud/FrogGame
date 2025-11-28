import Foundation
import GameKit
import UIKit

final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()

    private let leaderboardIdentifier = "com.froggyhopper.highscores"

    private override init() {
        super.init()
    }

    func authenticateLocalPlayer(presentingViewController: UIViewController? = nil) {
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] gcAuthVC, error in
            if let authVC = gcAuthVC {
                DispatchQueue.main.async {
                    if let presenter = presentingViewController ?? self?.topViewController() {
                        presenter.present(authVC, animated: true)
                    }
                }
            } else if localPlayer.isAuthenticated {
                print("Game Center authentication succeeded")
            } else if let error = error {
                print("Game Center authentication failed: \(error.localizedDescription)")
            }
        }
    }

    func report(score: Int, from viewController: UIViewController? = nil) {
        let submitScore = {
            let scoreReporter = GKScore(leaderboardIdentifier: self.leaderboardIdentifier)
            scoreReporter.value = Int64(score)

            GKScore.report([scoreReporter]) { error in
                if let error = error {
                    print("Failed to report Game Center score: \(error.localizedDescription)")
                }
            }
        }

        if GKLocalPlayer.local.isAuthenticated {
            submitScore()
        } else {
            authenticateLocalPlayer(presentingViewController: viewController)
            if GKLocalPlayer.local.isAuthenticated {
                submitScore()
            }
        }
    }

    func presentLeaderboard(from viewController: UIViewController) {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticateLocalPlayer(presentingViewController: viewController)
            return
        }

        let leaderboardController = GKGameCenterViewController(leaderboardID: leaderboardIdentifier, playerScope: .global, timeScope: .allTime)
        leaderboardController.gameCenterDelegate = self
        leaderboardController.viewState = .leaderboards
        viewController.present(leaderboardController, animated: true)
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseViewController = base ?? activeWindow()?.rootViewController

        if let navigationController = baseViewController as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }

        if let tabBarController = baseViewController as? UITabBarController {
            return topViewController(base: tabBarController.selectedViewController)
        }

        if let presented = baseViewController?.presentedViewController {
            return topViewController(base: presented)
        }

        return baseViewController
    }

    private func activeWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
