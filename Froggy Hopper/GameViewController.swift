//
//  GameViewController.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 3/18/23.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let skView = view as? SKView else { return }
        
        // Configure the view
        skView.ignoresSiblingOrder = true
        
        // Create the welcome scene
        let welcomeScene = WelcomeScene(size: skView.bounds.size)
        welcomeScene.scaleMode = .aspectFill
        skView.presentScene(welcomeScene)
        
        // Authenticate with Game Center ONCE at app launch
        GameCenterManager.shared.authenticate(from: self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Portrait for iPhone, all orientations for iPad to allow Game Center/alerts to present
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
