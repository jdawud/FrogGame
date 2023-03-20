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
    var frog: SKSpriteNode!
    var fly1Texture: SKTexture!
    var fly2Texture: SKTexture!
    var spider1Texture: SKTexture!
    var spider2Texture: SKTexture!
    var ant1Texture: SKTexture!
    var ant2Texture: SKTexture!
    var scoreLabel: SKLabelNode!
    var foodItems: [SKSpriteNode] = []
    var score = 0
    
    override func didMove(to view: SKView) {
        // Set up the game
        let background = SKSpriteNode(imageNamed: "jungle_floor")
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = -1
        let scaleFactor = size.height / background.size.height
        background.xScale = scaleFactor
        background.yScale = scaleFactor
        addChild(background)
        
        // Set up frog character
        frog = SKSpriteNode(imageNamed: "frog")
        frog.position = CGPoint(x: size.width / 2, y: size.height / 4)
        frog.zPosition = 1
        addChild(frog)
        
        // Set up food item textures
        fly1Texture = SKTexture(imageNamed: "fly1")
        fly2Texture = SKTexture(imageNamed: "fly2")
        spider1Texture = SKTexture(imageNamed: "spider1")
        spider2Texture = SKTexture(imageNamed: "spider2")
        ant1Texture = SKTexture(imageNamed: "ant1")
        ant2Texture = SKTexture(imageNamed: "ant2")
        
        // Set up score label
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 110)
        addChild(scoreLabel)
        
        // Spawn 4 initial food items
        for _ in 0..<4 {
            spawnFood()
        }
        
        // Set up timer to spawn new food items every 1.5 to 3 seconds
        let spawnAction = SKAction.run {
            self.spawnFood()
        }
        let randomSpawnTime = SKAction.wait(forDuration: TimeInterval.random(in: 1.5...3))
        let spawnSequence = SKAction.sequence([spawnAction, randomSpawnTime])
        let spawnRepeat = SKAction.repeatForever(spawnSequence)
        run(spawnRepeat)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle touch input
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let moveAction = SKAction.move(to: touchLocation, duration: 0.3)
        frog.run(moveAction)
        
        // Check for collisions with food items
        for foodItem in foodItems {
            if frog.frame.intersects(foodItem.frame) {
                foodItem.removeFromParent()
                switch foodItem.texture {
                case fly1Texture, fly2Texture:
                    score += 3
                case spider1Texture, spider2Texture:
                    score += 2
                case ant1Texture, ant2Texture:
                    score += 1
                default:
                    break
                }
                scoreLabel.text = "Score: \(score)"
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Update game state
        // You can add any necessary game state updates here
    }
}

