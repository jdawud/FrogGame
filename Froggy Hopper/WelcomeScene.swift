import SpriteKit
import UIKit

public class WelcomeScene: SKScene {

    // Track animation states
    private var isFrogJumping = false
    private var lastSpawnTime: TimeInterval = 0
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    private var layoutScale: CGFloat { isIPad ? 1.35 : 1.0 }

    public override func didMove(to view: SKView) {
        // Start background music
        SoundManager.shared.playBackgroundMusic(filename: "BackgroundMusic10.mp3")
        
        // Set up gradient background
        let background = SKSpriteNode()
        background.size = size
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = 0
        
        // Create gradient with natural green tones
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        gradientLayer.type = .axial
        gradientLayer.colors = [
            UIColor(red: 0.15, green: 0.6, blue: 0.3, alpha: 1.0).cgColor,  // Forest green at top
            UIColor(red: 0.12, green: 0.5, blue: 0.25, alpha: 1.0).cgColor, // Mid green
            UIColor(red: 0.1, green: 0.45, blue: 0.2, alpha: 1.0).cgColor   // Darker green at bottom
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]  // Weighted towards bottom for more natural look
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        // Convert gradient to image
        UIGraphicsBeginImageContext(size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Apply gradient to background
        background.texture = SKTexture(image: gradientImage!)
        addChild(background)
        
        // Create lily pad platform
        let lilyPad = SKSpriteNode(imageNamed: "lily_pad")
        lilyPad.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        lilyPad.xScale = 1.5 * layoutScale
        lilyPad.yScale = 1.5 * layoutScale
        lilyPad.zPosition = 1
        addChild(lilyPad)

        // Add welcome frog
        let frog = SKSpriteNode(imageNamed: "frog")
        frog.position = CGPoint(x: size.width/2, y: size.height * 0.4 + 20)
        frog.xScale = 1.3 * layoutScale
        frog.yScale = 1.3 * layoutScale
        frog.zPosition = 2
        frog.name = "welcomeFrog"
        addChild(frog)
        
        // Add idle animation to frog
        let scaleUp = SKAction.scaleX(to: 1.4, y: 1.3, duration: 0.5)
        let scaleDown = SKAction.scaleX(to: 1.3, y: 1.4, duration: 0.5)
        let breathe = SKAction.sequence([scaleUp, scaleDown])
        frog.run(SKAction.repeatForever(breathe))
        
        // Add title
        let titleLabel = SKLabelNode(fontNamed: "Chalkduster")
        titleLabel.text = "Froggy Feed!"
        titleLabel.fontSize = 41 * layoutScale
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        titleLabel.zPosition = 2
        addChild(titleLabel)
        
        // Add subtitle with animation
        let subtitleLabel = SKLabelNode(fontNamed: "Chalkduster")
        subtitleLabel.text = "Eat bugs, get points!"
        subtitleLabel.fontSize = 24 * layoutScale
        subtitleLabel.fontColor = .white
        subtitleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.6)
        subtitleLabel.zPosition = 2
        subtitleLabel.alpha = 0
        addChild(subtitleLabel)
        
        // Animate subtitle fade in
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        subtitleLabel.run(fadeIn)
        
        // Create stylized start button
        let buttonWidth: CGFloat = 240 * layoutScale
        let buttonHeight: CGFloat = 70 * layoutScale
        
        // Create button shadow
        let buttonShadow = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 20)
        buttonShadow.fillColor = UIColor(white: 0.0, alpha: 0.3)
        buttonShadow.strokeColor = .clear
        buttonShadow.position = CGPoint(x: size.width/2 + 4, y: size.height * 0.2 - 4)
        buttonShadow.zPosition = 1
        addChild(buttonShadow)
        
        // Create main button background with gradient
        let buttonBackground = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 20)
        buttonBackground.fillColor = .white
        buttonBackground.strokeColor = SKColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0)
        buttonBackground.lineWidth = 3
        buttonBackground.position = CGPoint(x: size.width/2, y: size.height * 0.2)
        buttonBackground.zPosition = 2
        buttonBackground.name = "startButton"
        
        // Add inner glow/highlight
        let innerGlow = SKShapeNode(rectOf: CGSize(width: buttonWidth - 10, height: buttonHeight - 10), cornerRadius: 15)
        innerGlow.fillColor = UIColor(white: 1.0, alpha: 0.5)
        innerGlow.strokeColor = .clear
        innerGlow.position = CGPoint(x: 0, y: 5)
        buttonBackground.addChild(innerGlow)
        
        addChild(buttonBackground)

        let startLabel = SKLabelNode(fontNamed: "Chalkduster")
        startLabel.text = "Start Game"
        startLabel.fontSize = 28 * layoutScale
        startLabel.fontColor = SKColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0)
        startLabel.position = CGPoint(x: 0, y: -10)
        startLabel.zPosition = 3
        startLabel.name = "startButton"
        buttonBackground.addChild(startLabel)

        // Create leaderboard button
        let leaderboardButton = SKShapeNode(rectOf: CGSize(width: 200 * layoutScale, height: 60 * layoutScale), cornerRadius: 15)
        leaderboardButton.fillColor = SKColor(red: 0.18, green: 0.65, blue: 0.38, alpha: 1.0)
        leaderboardButton.strokeColor = SKColor(white: 1.0, alpha: 0.8)
        leaderboardButton.lineWidth = 3
        leaderboardButton.position = CGPoint(x: size.width / 2, y: size.height * 0.08)
        leaderboardButton.zPosition = 2
        leaderboardButton.name = "leaderboardButton"
        addChild(leaderboardButton)

        let leaderboardLabel = SKLabelNode(fontNamed: "Chalkduster")
        leaderboardLabel.text = "Leaderboard"
        leaderboardLabel.fontSize = 22 * layoutScale
        leaderboardLabel.fontColor = .white
        leaderboardLabel.position = CGPoint(x: 0, y: -8)
        leaderboardLabel.zPosition = 3
        leaderboardLabel.name = "leaderboardButton"
        leaderboardButton.addChild(leaderboardLabel)
        
        // Add button animation
        let buttonScale = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        let shadowScale = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        buttonBackground.run(SKAction.repeatForever(buttonScale))
        buttonShadow.run(SKAction.repeatForever(shadowScale))
        
        // Set up random bug spawning
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnRandomBug()
        }
        let waitAction = SKAction.wait(forDuration: 2.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    private func spawnRandomBug() {
        let bugTextures = ["fly1", "fly2"]
        guard let randomBugName = bugTextures.randomElement() else { return }
        
        let bug = SKSpriteNode(imageNamed: randomBugName)
        bug.setScale(0.8)
        bug.zPosition = 5
        
        // Randomly choose start and end points
        let startFromLeft = Bool.random()
        let startX = startFromLeft ? -50 : size.width + 50
        let endX = startFromLeft ? size.width + 50 : -50
        
        // Apply the same working rotation to all flies
        bug.zRotation = startFromLeft ? -.pi/2 : .pi/2
        
        let randomY = CGFloat.random(in: size.height * 0.3...size.height * 0.8)
        bug.position = CGPoint(x: startX, y: randomY)
        
        // Add some vertical movement
        let moveY = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 30, duration: 1),
            SKAction.moveBy(x: 0, y: -30, duration: 1)
        ])
        
        // Create horizontal movement
        let moveX = SKAction.moveTo(x: endX, duration: 4)
        
        // Combine movements
        let group = SKAction.group([
            SKAction.repeatForever(moveY),
            moveX
        ])
        
        addChild(bug)
        bug.run(group) {
            bug.removeFromParent()
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "startButton" {
                // Add button press effect
                let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
                let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
                let sequence = SKAction.sequence([scaleDown, scaleUp])

                node.run(sequence) { [weak self] in
                    self?.startGame()
                }
                return
            } else if node.name == "leaderboardButton" {
                let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
                let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
                let sequence = SKAction.sequence([scaleDown, scaleUp])

                node.run(sequence) { [weak self] in
                    self?.showLeaderboard()
                }
                return
            }
        }
    }

    private func showLeaderboard() {
        guard let viewController = view?.window?.rootViewController else { return }
        GameCenterManager.shared.presentLeaderboard(from: viewController)
    }
    
    private func startGame() {
        // Create transition effect
        let transition = SKTransition.doorway(withDuration: 1.0)
        
        // Create and configure the game scene
        if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
            scene.scaleMode = .aspectFill
            // Switch to the game scene
            view?.presentScene(scene, transition: transition)
        }
    }
}
