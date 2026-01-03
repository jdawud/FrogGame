//
//  SceneDelegate.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 3/19/23.
//

/// Handles UIWindowScene lifecycle for the app.
///
/// Single source of truth for pause/resume behavior. Posts custom notifications
/// that GameScene observes to pause/resume its timer.

import Foundation
import UIKit
import SpriteKit

// MARK: - Game Pause/Resume Notifications

extension Notification.Name {
    /// Posted when the game should pause (app becoming inactive)
    static let gameShouldPause = Notification.Name("gameShouldPause")
    /// Posted when the game should resume (app became active)
    static let gameShouldResume = Notification.Name("gameShouldResume")
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let initialViewController = storyboard.instantiateInitialViewController() {
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
    }
    
    // MARK: - App Lifecycle Pause/Resume
    
    /// Pauses the game when app goes to background or becomes inactive
    func sceneWillResignActive(_ scene: UIScene) {
        print("⏸️ App becoming inactive - pausing game")
        pauseGame()
    }
    
    /// Resumes the game when app returns to foreground
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("▶️ App became active - resuming game")
        resumeGame()
    }
    
    /// Pauses background music, SKView, and notifies GameScene
    private func pauseGame() {
        // Pause background music
        SoundManager.shared.audioPlayer?.pause()
        
        // Pause the SKView (freezes all SpriteKit actions/physics)
        if let skView = findSKView() {
            skView.isPaused = true
        }
        
        // Notify GameScene to pause its timer
        NotificationCenter.default.post(name: .gameShouldPause, object: nil)
    }
    
    /// Resumes background music, SKView, and notifies GameScene
    private func resumeGame() {
        // Resume background music
        SoundManager.shared.audioPlayer?.play()
        
        // Resume the SKView
        if let skView = findSKView() {
            skView.isPaused = false
        }
        
        // Notify GameScene to resume its timer
        NotificationCenter.default.post(name: .gameShouldResume, object: nil)
    }
    
    /// Finds the SKView from the view hierarchy
    private func findSKView() -> SKView? {
        return window?.rootViewController?.view as? SKView
    }
}
