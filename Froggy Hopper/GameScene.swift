//
//  GameScene.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 3/18/23.
//

/// Core gameplay scene for Froggy Feed!
///
/// Manages the frog character, bug spawning, physics collisions, scoring, timer countdown,
/// and level progression. Handles user touch input to hop the frog toward food items while
/// avoiding obstacles. Reports scores and achievements to Game Center.

import SpriteKit

// MARK: - Game Configuration

/// Central configuration for gameplay constants.
/// Adjust these values to tune game difficulty and behavior.
enum GameConfig {
    /// Time limit per level in seconds
    static let levelDuration: TimeInterval = 120.0
    
    /// Points required to win a level
    static let pointsToWin: Int = 100
    
    /// Maximum hop distance for the frog in points
    static let maxHopDistance: CGFloat = 80.0
    
    /// Total number of levels in the game
    static let totalLevels: Int = 10
    
    /// Points awarded for eating a fly or spider
    static let flySpiderPoints: Int = 2
    
    /// Points awarded for eating an ant
    static let antPoints: Int = 1
}
import GameKit
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Game Elements
    var rock1Texture: SKTexture!
    var rock2Texture: SKTexture!
    var rock3Texture: SKTexture!
    var frog: SKSpriteNode!
    var fly1Texture: SKTexture!
    var fly2Texture: SKTexture!
    var spider1Texture: SKTexture!
    var spider2Texture: SKTexture!
    var ant1Texture: SKTexture!
    var ant2Texture: SKTexture!
    var scoreLabel: SKLabelNode!
    var foodItems: [SKSpriteNode] = []
    var obstacles: [SKSpriteNode] = []
    var score = 0
    var totalScore = 0  // Cumulative score across all levels
    var level: Int = 1
    var totalLevels: Int = GameConfig.totalLevels
    var gameTime: TimeInterval = GameConfig.levelDuration
    var gameTimer: Timer?
    var timerLabel: SKLabelNode!
    
    /// Tracks whether the game is currently paused (for app lifecycle)
    private var isPausedBySystem = false
    var isGameOver = false
    var backgroundMusicFiles: [String] = ["BackgroundMusic1.mp3", "BackgroundMusic2.mp3", "BackgroundMusic3.mp3", "BackgroundMusic4.mp3", "BackgroundMusic5.mp3", "BackgroundMusic6.mp3", "BackgroundMusic7.mp3", "BackgroundMusic8.mp3", "BackgroundMusic9.mp3", "BackgroundMusic10.mp3"]
    private var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    private var layoutScale: CGFloat { isIPad ? 1.35 : 1.0 }

    // Physics categories
    struct PhysicsCategory {
        static let none      : UInt32 = 0
        static let frog      : UInt32 = 0b1      // 1
        static let food      : UInt32 = 0b10     // 2
        static let obstacle  : UInt32 = 0b100    // 4
        static let all       : UInt32 = UInt32.max
    }

    override func didMove(to view: SKView) {
        // Set up physics world contact delegate
        physicsWorld.contactDelegate = self
        
        // Register for pause/resume notifications from SceneDelegate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameShouldPause),
            name: .gameShouldPause,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameShouldResume),
            name: .gameShouldResume,
            object: nil
        )
        
        loadLevel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Pause/Resume Handlers
    
    /// Called when SceneDelegate pauses the game
    @objc private func handleGameShouldPause() {
        guard !isGameOver else { return }
        print("⏸️ GameScene: Pausing game timer")
        isPausedBySystem = true
        gameTimer?.invalidate()
    }
    
    /// Called when SceneDelegate resumes the game
    @objc private func handleGameShouldResume() {
        guard !isGameOver, isPausedBySystem else { return }
        print("▶️ GameScene: Resuming game timer")
        isPausedBySystem = false
        startGameTimer()
    }

    func loadLevel() {

        // Stop the previous background music before starting a new one
        SoundManager.shared.stopBackgroundMusic()

        // If there's a background music file corresponding to the current level, play it
        if level <= backgroundMusicFiles.count {
            SoundManager.shared.playBackgroundMusic(filename: backgroundMusicFiles[level - 1])
        }

        // Remove all existing nodes to reset the level
        removeAllChildren()
        foodItems.removeAll()
        removeAllActions()

        // Set up the game based on the current level
        let backgroundName = "jungle_floor\(level)"
        let background = SKSpriteNode(imageNamed: backgroundName)

        // Set up the game
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = -1
        let scaleFactor: CGFloat
        if isIPad {
            let heightScale = size.height / background.size.height
            let widthScale = size.width / background.size.width
            scaleFactor = max(heightScale, widthScale)
        } else {
            scaleFactor = size.height / background.size.height
        }
        background.xScale = scaleFactor
        background.yScale = scaleFactor
        addChild(background)

        // Set up physics world
        self.physicsWorld.gravity = .zero

        // Set up frog character
        frog = SKSpriteNode(imageNamed: "frog")
        frog.position = CGPoint(x: size.width / 2, y: size.height / 4)
        frog.zPosition = 1
        frog.setScale(1.15 * layoutScale)  // Set frog size
        
        // Calculate physics body size (70% of visual size)
        let frogRadius = min(frog.size.width, frog.size.height) * 0.35
        frog.physicsBody = SKPhysicsBody(circleOfRadius: frogRadius)
        frog.physicsBody?.isDynamic = false
        frog.physicsBody?.categoryBitMask = PhysicsCategory.frog
        frog.physicsBody?.contactTestBitMask = PhysicsCategory.food
        frog.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(frog)

        // Set up food item textures
        fly1Texture = SKTexture(imageNamed: "fly1")
        fly2Texture = SKTexture(imageNamed: "fly2")
        spider1Texture = SKTexture(imageNamed: "spider1")
        spider2Texture = SKTexture(imageNamed: "spider2")
        ant1Texture = SKTexture(imageNamed: "ant1")
        ant2Texture = SKTexture(imageNamed: "ant2")

        // Set up obstacle textures
        rock1Texture = SKTexture(imageNamed: "rock1")
        rock2Texture = SKTexture(imageNamed: "rock2")
        rock3Texture = SKTexture(imageNamed: "rock3")

        // Set up score label
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 28 * layoutScale
        scoreLabel.fontColor = SKColor.red
        scoreLabel.position = CGPoint(x: (size.width / 2) - (isIPad ? 260 : 200), y: size.height - (isIPad ? 150 : 110))
        scoreLabel.zPosition = 2
        addChild(scoreLabel)

        // Set up timer label
        timerLabel = SKLabelNode(fontNamed: "Chalkduster")
        timerLabel.text = "Time: \(Int(gameTime))"
        timerLabel.fontSize = 28 * layoutScale
        timerLabel.fontColor = SKColor.red
        timerLabel.position = CGPoint(x: (size.width / 2 ) + (isIPad ? 260 : 200), y: size.height - (isIPad ? 150 : 110))
        timerLabel.zPosition = 2
        addChild(timerLabel)

        // Set up level label
        let levelLabel = SKLabelNode(fontNamed: "Chalkduster")
        levelLabel.text = "Level: \(level)"
        levelLabel.fontSize = 36 * layoutScale
        levelLabel.fontColor = SKColor.red
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - (isIPad ? 150 : 110))
        levelLabel.zPosition = 2
        addChild(levelLabel)

        // Spawn initial food items
        for _ in 0..<4 {
            spawnFood()
        }

        // Spawn initial obstacles
        for _ in 0..<10 {
            spawnObstacle()
        }

        // Set up timer to spawn new food items
        let spawnAction = SKAction.run {
            self.spawnFood()
        }
        let randomSpawnTime = SKAction.wait(forDuration: TimeInterval.random(in: 0.9...1.5))
        let spawnSequence = SKAction.sequence([spawnAction, randomSpawnTime])
        let spawnRepeat = SKAction.repeatForever(spawnSequence)
        run(spawnRepeat)

        // Start game timer
        startGameTimer()
    }

    func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.gameTime -= 1
            self.timerLabel.text = "Time: \(Int(self.gameTime))"

            if self.gameTime <= 0 {
                timer.invalidate()
                self.gameOver()
            }
        }
    }

    func gameOver() {
        SoundManager.shared.stopBackgroundMusic()
        isGameOver = true
        gameTimer?.invalidate()
        
        let wonLevel = score >= GameConfig.pointsToWin
        
        // Add current level score to cumulative total
        totalScore += score
        
        if wonLevel {
            // Player completed this level - report achievement
            GameCenterManager.shared.reportLevelComplete(level)
            
            if level >= totalLevels {
                // 🎉 Player completed the entire game!
                GameCenterManager.shared.reportGameComplete()
            }
        }
        
        // Always report cumulative score to leaderboard (Game Center keeps the highest)
        reportScoreToLeaderboard()
        
        // Determine display text
        let resultText: String
        let nodeName: String
        
        if wonLevel && level >= totalLevels {
            resultText = "You Beat the Game!"
            nodeName = "gameCompleteLabel"
        } else if wonLevel {
            resultText = "Frog Won!"
            nodeName = "nextLevelLabel"
        } else {
            resultText = "Try Again!"
            nodeName = "tryAgainLabel"
        }
        
        // Create a yellow background for the text
        let background = SKShapeNode(rectOf: CGSize(width: size.width / 2, height: 60), cornerRadius: 20)
        background.fillColor = .yellow
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 10
        addChild(background)

        let resultLabel = SKLabelNode(fontNamed: "Chalkduster")
        resultLabel.text = resultText
        resultLabel.fontSize = 32
        resultLabel.fontColor = SKColor.red
        resultLabel.position = CGPoint(x: 0, y: -resultLabel.frame.size.height / 2 + 14)
        resultLabel.zPosition = 10
        background.addChild(resultLabel)
        resultLabel.name = nodeName
    }

    /// Restarts the game at the specified level
    /// - Parameters:
    ///   - restartLevel: The level to start at
    ///   - resetTotalScore: Whether to reset the cumulative total score (true when starting fresh)
    func restartGame(restartLevel: Int, resetTotalScore: Bool = false) {
        isGameOver = false
        score = 0
        gameTime = GameConfig.levelDuration
        level = restartLevel
        
        // Reset total score if starting a completely new game
        if resetTotalScore {
            totalScore = 0
        }

        // Invalidate existing timer before starting a new one
        gameTimer?.invalidate()

        // Remove result labels
        for child in children {
            if child.name == "nextLevelLabel" || child.name == "tryAgainLabel" || child.name == "gameCompleteLabel" {
                child.removeFromParent()
            }
        }
        loadLevel()
    }

    /// Reports the total cumulative score to Game Center leaderboard
    private func reportScoreToLeaderboard() {
        GameCenterManager.shared.reportScore(totalScore)
    }

    // MARK: - Spawning methods moved to GameScene+Spawning.swift

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameOver {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: self)

            // Calculate the direction vector and normalize it
            let direction = CGPoint(x: touchLocation.x - frog.position.x, y: touchLocation.y - frog.position.y)
            let directionLength = sqrt(direction.x * direction.x + direction.y * direction.y)
            let normalizedDirection = CGPoint(x: direction.x / directionLength, y: direction.y / directionLength)

            // Mirror the frog image based on the direction of movement
            if normalizedDirection.x > 0 {
                frog.xScale = -abs(frog.xScale)
            } else {
                frog.xScale = abs(frog.xScale)
            }

            // Set the hop distance and calculate the new position
            let maxHopDistance: CGFloat = GameConfig.maxHopDistance
            var hopDistance: CGFloat = maxHopDistance

            // Use raycasting to detect obstacles in the path
            let rayEnd = CGPoint(x: frog.position.x + maxHopDistance * normalizedDirection.x, y: frog.position.y + maxHopDistance * normalizedDirection.y)
            physicsWorld.enumerateBodies(alongRayStart: frog.position, end: rayEnd) { (body, point, normal, stop) in
                if let obstacleNode = body.node {
                    let dx = obstacleNode.position.x - self.frog.position.x
                    let dy = obstacleNode.position.y - self.frog.position.y
                    let distanceToObstacle = sqrt(dx * dx + dy * dy)
                    let minDistance = (obstacleNode.frame.size.width / 2) + (self.frog.frame.size.width / 2) - 20

                    if distanceToObstacle < minDistance + maxHopDistance {
                        let allowedHopDistance = distanceToObstacle - minDistance
                        hopDistance = min(hopDistance, allowedHopDistance)
                        stop.pointee = true
                    }
                }
            }

            let newX = frog.position.x + normalizedDirection.x * hopDistance
            let newY = frog.position.y + normalizedDirection.y * hopDistance
            let newPosition = CGPoint(x: newX, y: newY)

            // Move the frog to the new position with a hop animation
            let moveAction = SKAction.move(to: newPosition, duration: 0.4)
            let jumpUpAction = SKAction.moveBy(x: 0, y: 10, duration: 0.1)
            let jumpDownAction = SKAction.moveBy(x: 0, y: -10, duration: 0.1)
            let jumpSequence = SKAction.sequence([jumpUpAction, moveAction, jumpDownAction])
            frog.run(jumpSequence)
        } else {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: self)
            let touchedNodes = nodes(at: touchLocation)
            for node in touchedNodes {
                if node.name == "tryAgainLabel" {
                    // Retry current level - don't reset total score, just this level's score
                    restartGame(restartLevel: level, resetTotalScore: false)
                } else if node.name == "nextLevelLabel" {
                    // Advance to next level
                    let nextLevel = level + 1
                    restartGame(restartLevel: nextLevel, resetTotalScore: false)
                } else if node.name == "gameCompleteLabel" {
                    // Beat the game! Start fresh from level 1
                    restartGame(restartLevel: 1, resetTotalScore: true)
                }
            }
        }
    }

    // Create particle effect for bug consumption
    func createEatingEffect(at position: CGPoint, color: SKColor) {
        guard let particleEmitter = SKEmitterNode(fileNamed: "BugSplat") else {
            // Fallback if particle file doesn't exist
            let particles = SKEmitterNode()
            particles.particleTexture = SKTexture(imageNamed: "spark")
            particles.position = position
            particles.particleBirthRate = 100
            particles.numParticlesToEmit = 10
            particles.particleLifetime = 0.5
            particles.particleSpeed = 50
            particles.particleSpeedRange = 20
            particles.particleColor = color
            particles.particleColorBlendFactor = 1.0
            particles.particleScale = 0.2
            particles.particleScaleRange = 0.1
            particles.emissionAngle = 0.0
            particles.emissionAngleRange = CGFloat.pi * 2
            particles.particleAlpha = 0.8
            particles.particleAlphaSpeed = -1.0
            
            addChild(particles)
            let waitAction = SKAction.wait(forDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            particles.run(SKAction.sequence([waitAction, removeAction]))
            return
        }
        
        // Configure and add the loaded particle emitter
        particleEmitter.position = position
        particleEmitter.particleColor = color
        particleEmitter.particleColorBlendFactor = 1.0
        addChild(particleEmitter)
        
        // Remove after animation completes
        let waitAction = SKAction.wait(forDuration: 0.5)
        let removeAction = SKAction.removeFromParent()
        particleEmitter.run(SKAction.sequence([waitAction, removeAction]))
    }

    // Replace checkForCollisionsWithFoodItems with physics contact handling
    func didBegin(_ contact: SKPhysicsContact) {
        // Ensure we're still playing
        guard !isGameOver else { return }
        
        var foodNode: SKSpriteNode?
        
        // Sort out which node is the food
        if contact.bodyA.categoryBitMask == PhysicsCategory.food {
            foodNode = contact.bodyA.node as? SKSpriteNode
        } else if contact.bodyB.categoryBitMask == PhysicsCategory.food {
            foodNode = contact.bodyB.node as? SKSpriteNode
        }
        
        guard let food = foodNode else { return }
        
        // Double check the distance (belt and suspenders approach)
        let dx = food.position.x - frog.position.x
        let dy = food.position.y - frog.position.y
        let distanceToFood = sqrt(dx * dx + dy * dy)
        let maxCollisionDistance = (food.size.width + frog.size.width) * 0.4  // 40% of combined sizes
        
        guard distanceToFood <= maxCollisionDistance else { return }
        
        // Create particle effect based on food type
        var particleColor: SKColor
        var points = 0
        
        switch food.texture {
        case fly1Texture, fly2Texture:
            particleColor = .green
            points = GameConfig.flySpiderPoints
        case spider1Texture, spider2Texture:
            particleColor = .brown
            points = GameConfig.flySpiderPoints
        case ant1Texture, ant2Texture:
            particleColor = .red
            points = GameConfig.antPoints
        default:
            particleColor = .white
            points = 0
        }
        
        // Create eating effect
        createEatingEffect(at: food.position, color: particleColor)
        
        // Play sound effect and haptic feedback
        SoundManager.shared.playSoundEffect(named: "eat_sound.mp3")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        // Update score
        score += points
        scoreLabel.text = "Score: \(score)"
        
        // Remove the food
        food.removeFromParent()
        if let index = foodItems.firstIndex(of: food) {
            foodItems.remove(at: index)
        }
        
        // Add score popup
        let scorePopup = SKLabelNode(fontNamed: "Chalkduster")
        scorePopup.text = "+\(points)"
        scorePopup.fontSize = 24
        scorePopup.fontColor = .yellow
        scorePopup.position = food.position
        scorePopup.zPosition = 3
        addChild(scorePopup)
        
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        scorePopup.run(SKAction.sequence([group, remove]))
    }

}
