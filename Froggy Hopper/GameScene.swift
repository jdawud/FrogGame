//
//  GameScene.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 3/18/23.
//

import SpriteKit
import GameplayKit
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Initialize the game elements
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
    var level: Int = 1
    var totalLevels: Int = 10
    var gameTime: TimeInterval = 120.0
    var gameTimer: Timer?
    var timerLabel: SKLabelNode!
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
        loadLevel()
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
        let resultText = score >= 100 ? "Frog Won!" : "Try Again!"
        let nodeName = score >= 100 ? "nextLevelLabel" : "tryAgainLabel"
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

    func restartGame(restartLevel: Int) {
        isGameOver = false
        score = 0
        gameTime = 120.0
        level = restartLevel

        // Invalidate existing timer before starting a new one
        gameTimer?.invalidate()

        // Remove "You Won!" or "Try Again!" labels
        for child in children {
            if child.name == "nextLevelLabel" || child.name == "tryAgainLabel" {
                child.removeFromParent()
            }
        }
        loadLevel()
    }

    func spawnFood() {
        // Spawn multiple food items at once
        let foodTextures = [fly1Texture, fly2Texture, spider1Texture, spider2Texture, ant1Texture, ant2Texture]
        
        // Spawn 2-3 items at once
        let spawnCount = Int.random(in: 2...3)
        
        for _ in 0..<spawnCount {
            // Spawn a random food item at a random location
            let randomIndex = Int.random(in: 0..<foodTextures.count)
            let foodTexture = foodTextures[randomIndex]
            let foodItem = SKSpriteNode(texture: foodTexture)
            
            // Set size based on food type
            switch foodTexture {
            case spider1Texture, spider2Texture:
                foodItem.setScale(1.5)  // Make spiders 50% bigger
            case ant1Texture, ant2Texture:
                foodItem.setScale(1.3)  // Make ants 30% bigger
            default:
                break  // Keep flies at normal size
            }
            
            // Ensure food spawns away from the frog
            let minDistance: CGFloat = 100  // Minimum spawn distance from frog
            var randomX: CGFloat
            var randomY: CGFloat
            var distanceFromFrog: CGFloat
            
            repeat {
                randomX = CGFloat.random(in: 0..<size.width)
                randomY = CGFloat.random(in: 0..<size.height)
                let dx = randomX - frog.position.x
                let dy = randomY - frog.position.y
                distanceFromFrog = sqrt(dx * dx + dy * dy)
            } while distanceFromFrog < minDistance
            
            foodItem.position = CGPoint(x: randomX, y: randomY)
            foodItem.zPosition = 1
            foodItem.name = "food"
            
            // Calculate physics body size (60% of visual size for better precision)
            let foodPhysicsRadius = min(foodItem.size.width, foodItem.size.height) * 0.3
            foodItem.physicsBody = SKPhysicsBody(circleOfRadius: foodPhysicsRadius)
            foodItem.physicsBody?.isDynamic = true
            foodItem.physicsBody?.affectedByGravity = false
            foodItem.physicsBody?.categoryBitMask = PhysicsCategory.food
            foodItem.physicsBody?.contactTestBitMask = PhysicsCategory.frog
            foodItem.physicsBody?.collisionBitMask = PhysicsCategory.none
            
            addChild(foodItem)
            foodItems.append(foodItem)

            // Make the food item move
            let randomDistance = CGFloat.random(in: 2...20)
            let randomRotation = CGFloat.random(in: -50...50)
            let randomAngle = CGFloat.random(in: 0...360) * CGFloat.pi / 180
            let dx = randomDistance * cos(randomAngle)
            let dy = randomDistance * sin(randomAngle)
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
            let rotate = SKAction.rotate(byAngle: randomRotation * CGFloat.pi / 180, duration: 0.3)
            let moveThenRotate = SKAction.sequence([move, rotate])
            let moveThenRotateRepeat = SKAction.repeatForever(moveThenRotate)
            foodItem.run(moveThenRotateRepeat)

            // Remove the food item after 10 seconds
            let removeAction = SKAction.removeFromParent()
            let waitAction = SKAction.wait(forDuration: 10)
            let removalSequence = SKAction.sequence([waitAction, removeAction])
            foodItem.run(removalSequence)
        }
    }

    func spawnObstacle() {
        // Spawn a random rock obstacle at a random location
        let obstacleTextures = [rock1Texture, rock2Texture, rock3Texture]
        let randomIndex = Int.random(in: 0..<obstacleTextures.count)
        let obstacleTexture = obstacleTextures[randomIndex]
        let obstacle = SKSpriteNode(texture: obstacleTexture)
        
        // Ensure obstacles spawn away from the frog
        let minDistance: CGFloat = 100  // Minimum spawn distance from frog
        var randomX: CGFloat
        var randomY: CGFloat
        var distanceFromFrog: CGFloat
        
        repeat {
            randomX = CGFloat.random(in: 0..<size.width)
            randomY = CGFloat.random(in: 0..<size.height)
            let dx = randomX - frog.position.x
            let dy = randomY - frog.position.y
            distanceFromFrog = sqrt(dx * dx + dy * dy)
        } while distanceFromFrog < minDistance

        obstacle.position = CGPoint(x: randomX, y: randomY)
        obstacle.zPosition = 1
        addChild(obstacle)
        obstacles.append(obstacle)

        // Set up circular physics body for rock
        let obstacleRadius = min(obstacle.size.width, obstacle.size.height) * 0.25
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: obstacleRadius)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        obstacle.physicsBody?.collisionBitMask = PhysicsCategory.none
    }

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
            let maxHopDistance: CGFloat = 80
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
                    restartGame(restartLevel: level) // Keep the current level if "Try Again!" is pressed
                } else if node.name == "nextLevelLabel" {
                    let nextLevel = (level % totalLevels) + 1
                    restartGame(restartLevel: nextLevel) // Switch to the next level if "You Won!" is pressed
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
            points = 2
        case spider1Texture, spider2Texture:
            particleColor = .brown
            points = 2
        case ant1Texture, ant2Texture:
            particleColor = .red
            points = 1
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

    override func update(_ currentTime: TimeInterval) {
        // Update game state
        // You can add any necessary game state updates here
    }
}
