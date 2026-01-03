//
//  GameScene+Spawning.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 1/3/26.
//

/// Extension for food and obstacle spawning logic.
/// Extracted from GameScene to improve readability and separation of concerns.

import SpriteKit

extension GameScene {
    
    // MARK: - Food Spawning
    
    /// Spawns 2-3 random food items at positions away from the frog
    func spawnFood() {
        let foodTextures = [fly1Texture, fly2Texture, spider1Texture, spider2Texture, ant1Texture, ant2Texture]
        let spawnCount = Int.random(in: 2...3)
        
        for _ in 0..<spawnCount {
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
            
            // Position away from frog
            foodItem.position = randomPositionAwayFromFrog(minDistance: 100)
            foodItem.zPosition = 1
            foodItem.name = "food"
            
            // Physics body (60% of visual size for better precision)
            let foodPhysicsRadius = min(foodItem.size.width, foodItem.size.height) * 0.3
            foodItem.physicsBody = SKPhysicsBody(circleOfRadius: foodPhysicsRadius)
            foodItem.physicsBody?.isDynamic = true
            foodItem.physicsBody?.affectedByGravity = false
            foodItem.physicsBody?.categoryBitMask = PhysicsCategory.food
            foodItem.physicsBody?.contactTestBitMask = PhysicsCategory.frog
            foodItem.physicsBody?.collisionBitMask = PhysicsCategory.none
            
            addChild(foodItem)
            foodItems.append(foodItem)
            
            // Animate food movement
            animateFoodItem(foodItem)
            
            // Remove after 10 seconds
            let removeSequence = SKAction.sequence([
                SKAction.wait(forDuration: 10),
                SKAction.removeFromParent()
            ])
            foodItem.run(removeSequence)
        }
    }
    
    /// Animates a food item with random movement and rotation
    private func animateFoodItem(_ foodItem: SKSpriteNode) {
        let randomDistance = CGFloat.random(in: 2...20)
        let randomRotation = CGFloat.random(in: -50...50)
        let randomAngle = CGFloat.random(in: 0...360) * CGFloat.pi / 180
        let dx = randomDistance * cos(randomAngle)
        let dy = randomDistance * sin(randomAngle)
        
        let move = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
        let rotate = SKAction.rotate(byAngle: randomRotation * CGFloat.pi / 180, duration: 0.3)
        let moveThenRotate = SKAction.sequence([move, rotate])
        foodItem.run(SKAction.repeatForever(moveThenRotate))
    }
    
    // MARK: - Obstacle Spawning
    
    /// Spawns a random rock obstacle at a position away from the frog
    func spawnObstacle() {
        let obstacleTextures = [rock1Texture, rock2Texture, rock3Texture]
        let randomIndex = Int.random(in: 0..<obstacleTextures.count)
        let obstacleTexture = obstacleTextures[randomIndex]
        let obstacle = SKSpriteNode(texture: obstacleTexture)
        
        obstacle.position = randomPositionAwayFromFrog(minDistance: 100)
        obstacle.zPosition = 1
        addChild(obstacle)
        obstacles.append(obstacle)
        
        // Circular physics body for rock
        let obstacleRadius = min(obstacle.size.width, obstacle.size.height) * 0.25
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: obstacleRadius)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        obstacle.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    // MARK: - Helpers
    
    /// Returns a random position that is at least `minDistance` away from the frog
    private func randomPositionAwayFromFrog(minDistance: CGFloat) -> CGPoint {
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
        
        return CGPoint(x: randomX, y: randomY)
    }
}
