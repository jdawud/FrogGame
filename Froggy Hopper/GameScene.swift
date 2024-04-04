//
//  GameScene.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 3/18/23.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // Initialize the game elements
    var rock1Texture: SKTexture!
    var rock2Texture: SKTexture!
    var rock3Texture: SKTexture!
    var log1Texture: SKTexture!
    var log2Texture: SKTexture!
    var log3Texture: SKTexture!
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

    override func didMove(to view: SKView) {
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
        let scaleFactor = size.height / background.size.height
        background.xScale = scaleFactor
        background.yScale = scaleFactor
        addChild(background)

        // Set up physics world
        self.physicsWorld.gravity = .zero

        // Set up frog character
        frog = SKSpriteNode(imageNamed: "frog")
        frog.position = CGPoint(x: size.width / 2, y: size.height / 4)
        frog.zPosition = 1
        addChild(frog)

        // Set up frog physics body
        frog.physicsBody = SKPhysicsBody(rectangleOf: frog.size)
        frog.physicsBody?.isDynamic = false

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
        log1Texture = SKTexture(imageNamed: "log1")
        log2Texture = SKTexture(imageNamed: "log2")
        log3Texture = SKTexture(imageNamed: "log3")

        // Set up score label
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = SKColor.red
        scoreLabel.position = CGPoint(x: (size.width / 2) - 200, y: size.height - 110)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)

        // Set up timer label
        timerLabel = SKLabelNode(fontNamed: "Chalkduster")
        timerLabel.text = "Time: \(Int(gameTime))"
        timerLabel.fontSize = 28
        timerLabel.fontColor = SKColor.red
        timerLabel.position = CGPoint(x: (size.width / 2 ) + 200, y: size.height - 110)
        timerLabel.zPosition = 2
        addChild(timerLabel)

        // Set up level label
        let levelLabel = SKLabelNode(fontNamed: "Chalkduster")
        levelLabel.text = "Level: \(level)"
        levelLabel.fontSize = 36
        levelLabel.fontColor = SKColor.red
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 110)
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

        // Set up timer to spawn new food items every 1.5 to 3 seconds
        let spawnAction = SKAction.run {
            self.spawnFood()
        }
        let randomSpawnTime = SKAction.wait(forDuration: TimeInterval.random(in: 1.5...3))
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
        // Spawn a random food item at a random location
        let foodTextures = [fly1Texture, fly2Texture, spider1Texture, spider2Texture, ant1Texture, ant2Texture]

        for _ in 0..<1 {
            let randomIndex = Int.random(in: 0..<foodTextures.count)
            let foodTexture = foodTextures[randomIndex]
            let foodItem = SKSpriteNode(texture: foodTexture)
            let randomX = CGFloat.random(in: 0..<size.width)
            let randomY = CGFloat.random(in: 0..<size.height)

            foodItem.position = CGPoint(x: randomX, y: randomY)
            foodItem.zPosition = 1
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
    // Spawn a random obstacle at a random location
        let obstacleTextures = [rock1Texture, rock2Texture, rock3Texture, log1Texture, log2Texture, log3Texture]
        let randomIndex = Int.random(in: 0..<obstacleTextures.count)
        let obstacleTexture = obstacleTextures[randomIndex]
        let obstacle = SKSpriteNode(texture: obstacleTexture)
        let randomX = CGFloat.random(in: 0..<size.width)
        let randomY = CGFloat.random(in: 0..<size.height)

        obstacle.position = CGPoint(x: randomX, y: randomY)
        obstacle.zPosition = 1
        addChild(obstacle)
        obstacles.append(obstacle)

        // Set up obstacle physics body
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.affectedByGravity = false
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

                    print("Raycast: Obstacle at \(obstacleNode.position), Frog at \(self.frog.position), Distance to obstacle: \(distanceToObstacle), Min distance: \(minDistance)")

                    if distanceToObstacle < minDistance + maxHopDistance {
                        let allowedHopDistance = distanceToObstacle - minDistance
                        hopDistance = min(hopDistance, allowedHopDistance)
                        print("Obstacle detected. Adjusting hop distance to \(hopDistance).")
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
            let checkCollisionAction = SKAction.run {
                self.checkForCollisionsWithFoodItems()
            }
            let jumpSequence = SKAction.sequence([jumpUpAction, moveAction, jumpDownAction, checkCollisionAction])
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

    func checkForCollisionsWithFoodItems() {
        // Prevent the score from increasing if the game is over
        guard !isGameOver else { return }
        for foodItem in self.foodItems {
            let dx = foodItem.position.x - self.frog.position.x
            let dy = foodItem.position.y - self.frog.position.y
            let distanceToFood = sqrt(dx * dx + dy * dy)
            let minDistance = (foodItem.size.width / 2) + (self.frog.size.width / 2)

            print("Checking collision: FoodItem at \(foodItem.position), Frog at \(self.frog.position), Distance to food: \(distanceToFood), Min distance: \(minDistance)")

            // Update score and provide haptic feedback
            if distanceToFood < minDistance {
                print("Collision detected with food item. Updating score.")
                foodItem.removeFromParent()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
                switch foodItem.texture {
                case self.fly1Texture, self.fly2Texture:
                    self.score += 2
                case self.spider1Texture, self.spider2Texture, self.ant1Texture, self.ant2Texture:
                    self.score += 1
                default:
                    break
                }
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Update game state
        // You can add any necessary game state updates here
    }
}
