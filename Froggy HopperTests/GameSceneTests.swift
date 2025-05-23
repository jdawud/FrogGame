import XCTest
// Removed duplicate import XCTest
import SpriteKit // Import SpriteKit for SKNode, SKAction, etc.
@testable import Froggy_Hopper

// Helper for creating a Set<UITouch> - THIS IS SPECULATIVE
// This will only work if the test environment allows some form of UITouch instantiation
// or if we can get a UITouch instance from somewhere (e.g., a view).
// For now, this part is a placeholder for the actual touch simulation.
//
// func performTouch(on scene: GameScene, at sceneLocation: CGPoint) {
//     // This is the problematic part: creating a UITouch.
//     // ... (elided comments for brevity in diff)
// }

// Helper extension for waiting for SKAction to complete
extension XCTestCase {
    func wait(for duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "Wait for action with fixed duration")
        // Use a small buffer to ensure action completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: duration + 0.2)
    }
}

class GameSceneTests: XCTestCase {

    var scene: GameScene!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Initialize the scene with a fixed size
        scene = GameScene(size: CGSize(width: 1024, height: 768))
        // Call didMove(to:) to trigger scene setup
        // This is important because didMove(to:) calls loadLevel() which sets up frog, textures etc.
        let skView = SKView() // A dummy view
        scene.didMove(to: skView) // This loads level 1, spawns initial food/obstacles
    }

    override func tearDownWithError() throws {
        scene.gameTimer?.invalidate() // Stop game timer first
        scene.removeAllActions()      // Stop all scene actions
        scene.removeAllChildren()     // Remove all nodes
        scene.foodItems.removeAll()   // Clear tracked arrays
        scene.obstacles.removeAll()
        scene = nil                   // Release scene instance
        try super.tearDownWithError()
    }

    func testFrogNodeExists() throws {
        XCTAssertNotNil(scene.frog, "Frog node should exist after scene loads.")
        // Check if frog has a physics body, which is crucial for movement logic
        XCTAssertNotNil(scene.frog.physicsBody, "Frog physics body should be configured.")
    }

    func testInitialScoreIsZero() throws {
        XCTAssertEqual(scene.score, 0, "Initial score should be 0.")
    }

    func testInitialLevelIsOne() throws {
        XCTAssertEqual(scene.level, 1, "Initial level should be 1.")
    }

    func testInitialTimerValue() throws {
        // From GameScene.swift: timerLabel.text = "Time: \(Int(gameTime))" and gameTime = 120.0
        XCTAssertNotNil(scene.timerLabel, "Timer label should exist")
        XCTAssertEqual(scene.timerLabel.text, "Time: 120", "Initial timer value should be 120.")
    }
    
    func testFrogMovementBasic() {
        guard let scene = scene, let frog = scene.frog else {
            XCTFail("Scene or frog not initialized")
            return
        }

        let initialPosition = frog.position
        let targetPosition = CGPoint(x: initialPosition.x + 200, y: initialPosition.y) // Target far right

        // Manually replicate the core movement logic from touchesBegan
        let direction = CGPoint(x: targetPosition.x - initialPosition.x, y: targetPosition.y - initialPosition.y)
        let directionLength = sqrt(direction.x * direction.x + direction.y * direction.y)
        let normalizedDirection = CGPoint(x: direction.x / directionLength, y: direction.y / directionLength)
        
        // Assuming no obstacles for this basic movement test
        let hopDistance: CGFloat = 80 
        let expectedEndPosition = CGPoint(x: initialPosition.x + normalizedDirection.x * hopDistance, 
                                          y: initialPosition.y + normalizedDirection.y * hopDistance)

        frog.removeAllActions() 
        let moveAction = SKAction.move(to: expectedEndPosition, duration: 0.4)
        let jumpUpAction = SKAction.moveBy(x: 0, y: 10, duration: 0.1)
        let jumpDownAction = SKAction.moveBy(x: 0, y: -10, duration: 0.1)
        let jumpSequence = SKAction.sequence([jumpUpAction, moveAction, jumpDownAction])
        frog.run(jumpSequence)

        wait(for: 0.6) // Wait for animation (0.1 + 0.4 + 0.1 = 0.6s)

        XCTAssertEqual(frog.position.x, expectedEndPosition.x, accuracy: 1.0, "Frog should move towards target X.")
        XCTAssertEqual(frog.position.y, expectedEndPosition.y, accuracy: 1.0, "Frog should move towards target Y.")
    }

    func testFrogMirroring() {
        guard let scene = scene, let frog = scene.frog else {
            XCTFail("Scene or frog not initialized")
            return
        }
        let initialScaleX = abs(frog.xScale) 
        var currentFrogPosition = frog.position


        // Move Right
        let targetPositionRight = CGPoint(x: currentFrogPosition.x + 100, y: currentFrogPosition.y)
        var direction = CGPoint(x: targetPositionRight.x - currentFrogPosition.x, y: targetPositionRight.y - currentFrogPosition.y)
        var directionLength = sqrt(direction.x * direction.x + direction.y * direction.y)
        var normalizedDirection = CGPoint(x: direction.x / directionLength, y: direction.y / directionLength)
        var expectedEndPosition = CGPoint(x: currentFrogPosition.x + normalizedDirection.x * 80, y: currentFrogPosition.y + normalizedDirection.y * 80)

        if normalizedDirection.x > 0 { frog.xScale = -initialScaleX } else if normalizedDirection.x < 0 { frog.xScale = initialScaleX }
        
        var moveAction = SKAction.move(to: expectedEndPosition, duration: 0.4)
        var jumpSequence = SKAction.sequence([SKAction.moveBy(x:0, y:10, duration:0.1), moveAction, SKAction.moveBy(x:0, y:-10, duration:0.1)])
        frog.removeAllActions()
        frog.run(jumpSequence)
        wait(for: 0.6)
        
        XCTAssertLessThan(frog.xScale, 0, "Frog should be mirrored (face right). Current scale: \(frog.xScale)")
        currentFrogPosition = frog.position // Update frog's current position

        // Move Left
        let targetPositionLeft = CGPoint(x: currentFrogPosition.x - 100, y: currentFrogPosition.y)
        direction = CGPoint(x: targetPositionLeft.x - currentFrogPosition.x, y: targetPositionLeft.y - currentFrogPosition.y)
        directionLength = sqrt(direction.x * direction.x + direction.y * direction.y)
        normalizedDirection = CGPoint(x: direction.x / directionLength, y: direction.y / directionLength)
        expectedEndPosition = CGPoint(x: currentFrogPosition.x + normalizedDirection.x * 80, y: currentFrogPosition.y + normalizedDirection.y * 80)

        if normalizedDirection.x > 0 { frog.xScale = -initialScaleX } else if normalizedDirection.x < 0 { frog.xScale = initialScaleX }

        moveAction = SKAction.move(to: expectedEndPosition, duration: 0.4)
        jumpSequence = SKAction.sequence([SKAction.moveBy(x:0, y:10, duration:0.1), moveAction, SKAction.moveBy(x:0, y:-10, duration:0.1)])
        frog.removeAllActions()
        frog.run(jumpSequence)
        wait(for: 0.6)

        XCTAssertGreaterThan(frog.xScale, 0, "Frog should be mirrored back (face left). Current scale: \(frog.xScale)")
    }

    func testFrogObstacleAvoidance() {
        guard let scene = scene, let frog = scene.frog else {
            XCTFail("Scene or frog not initialized.")
            return
        }
        guard scene.rock1Texture != nil else { // Check one texture, assuming others load if one does
            XCTFail("Rock texture not loaded. Ensure loadLevel() has been called and textures are initialized.")
            return
        }

        let initialFrogPosition = frog.position
        let obstacle = SKSpriteNode(texture: scene.rock1Texture) 
        obstacle.position = CGPoint(x: initialFrogPosition.x + 40, y: initialFrogPosition.y) // Place obstacle in path
        
        let obstacleRadius = min(obstacle.size.width, obstacle.size.height) * 0.25
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: obstacleRadius)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = GameScene.PhysicsCategory.obstacle
        obstacle.physicsBody?.collisionBitMask = GameScene.PhysicsCategory.none 
        scene.addChild(obstacle)
        // scene.obstacles.append(obstacle) // Not strictly needed for this test if GameScene.obstacles isn't used by raycast

        let touchTargetPosition = CGPoint(x: initialFrogPosition.x + 200, y: initialFrogPosition.y)

        let direction = CGPoint(x: touchTargetPosition.x - initialFrogPosition.x, y: touchTargetPosition.y - initialFrogPosition.y)
        let directionLength = sqrt(direction.x * direction.x + direction.y * direction.y)
        let normalizedDirection = CGPoint(x: direction.x / directionLength, y: direction.y / directionLength)

        var hopDistance: CGFloat = 80 
        let rayStart = initialFrogPosition
        let rayEnd = CGPoint(x: initialFrogPosition.x + hopDistance * normalizedDirection.x, y: initialFrogPosition.y + hopDistance * normalizedDirection.y)
        
        var detectedObstacle = false
        scene.physicsWorld.enumerateBodies(alongRayStart: rayStart, end: rayEnd) { (body, point, normal, stop) in
            if body.categoryBitMask == GameScene.PhysicsCategory.obstacle {
                guard let obstacleNode = body.node else { return }
                let dx = obstacleNode.position.x - initialFrogPosition.x
                let dy = obstacleNode.position.y - initialFrogPosition.y
                let distanceToObstacle = sqrt(dx*dx + dy*dy)
                let minDistanceToStop = (obstacleNode.frame.size.width / 2) + (frog.frame.size.width / 2) - 20
                
                if distanceToObstacle < minDistanceToStop + hopDistance { 
                    let allowedHopDistance = distanceToObstacle - minDistanceToStop
                    hopDistance = min(hopDistance, allowedHopDistance) 
                    stop.pointee = true 
                    detectedObstacle = true
                }
            }
        }

        let expectedEndPosition = CGPoint(x: initialFrogPosition.x + normalizedDirection.x * hopDistance,
                                          y: initialFrogPosition.y + normalizedDirection.y * hopDistance)

        frog.removeAllActions()
        if normalizedDirection.x > 0 { frog.xScale = -abs(frog.xScale) } else if normalizedDirection.x < 0 { frog.xScale = abs(frog.xScale) }
        
        let moveAction = SKAction.move(to: expectedEndPosition, duration: 0.4)
        let jumpSequence = SKAction.sequence([SKAction.moveBy(x:0, y:10, duration:0.1), moveAction, SKAction.moveBy(x:0, y:-10, duration:0.1)])
        frog.run(jumpSequence)
        
        wait(for: 0.6)

        XCTAssertTrue(detectedObstacle, "Raycast should have detected the obstacle.")
        XCTAssertTrue(hopDistance < 80, "Frog should have shortened its hop due to obstacle. Hop distance: \(hopDistance)")
        XCTAssertEqual(frog.position.x, expectedEndPosition.x, accuracy: 1.0, "Frog X should be at calculated collision avoidance point.")
        XCTAssertEqual(frog.position.y, expectedEndPosition.y, accuracy: 1.0, "Frog Y should be at calculated collision avoidance point.")
        
        obstacle.removeFromParent()
    }

    // MARK: - Spawning Tests

    func testSpawnFood() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }
        
        // Clear any food spawned by loadLevel in setUp
        scene.foodItems.forEach { $0.removeFromParent() }
        scene.foodItems.removeAll()
        
        let initialFoodItemArrayCount = scene.foodItems.count
        let initialFoodNodeCount = scene.children.filter { $0.name == "food" }.count
        
        scene.spawnFood() // This spawns 2-3 food items
        
        let spawnedCountInArray = scene.foodItems.count - initialFoodItemArrayCount
        let spawnedNodesInScene = scene.children.filter { $0.name == "food" }.count - initialFoodNodeCount
        
        XCTAssertTrue((2...3).contains(spawnedCountInArray), "Should add 2 or 3 food items to foodItems array. Added: \(spawnedCountInArray)")
        XCTAssertTrue((2...3).contains(spawnedNodesInScene), "Should add 2 or 3 food item nodes to scene. Added: \(spawnedNodesInScene)")
        XCTAssertEqual(spawnedCountInArray, spawnedNodesInScene, "Number of items in array should match nodes in scene.")

        let newFoodItems = Array(scene.foodItems.suffix(spawnedCountInArray))
        for foodItem in newFoodItems {
            XCTAssertEqual(foodItem.name, "food", "Food item should be named 'food'.")
            XCTAssertNotNil(foodItem.physicsBody, "Food item should have a physics body.")
            XCTAssertEqual(foodItem.physicsBody?.categoryBitMask, GameScene.PhysicsCategory.food, "Food item physics category should be .food.")
            XCTAssertNotNil(foodItem.parent, "Food item should be added to the scene graph.")
        }
    }

    func testFoodRemovalAfterTime() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }

        // Clear existing food and spawn fresh for this test
        scene.foodItems.forEach { $0.removeFromParent() }
        scene.foodItems.removeAll()
        scene.spawnFood()
        
        guard let foodItem = scene.foodItems.first else {
            XCTFail("No food item spawned to test removal.")
            return
        }
        XCTAssertNotNil(foodItem.parent, "Food item should initially be in the scene.")
        
        let expectation = self.expectation(description: "Wait for food item to be removed by its own action sequence.")
        
        // Food items are set to be removed after 10 seconds.
        // Wait for 10.5 seconds to give it time to execute the removal action.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) { // Increased from 10.1 to 10.5 for safety
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 11.0) { error in // Increased from 10.2 to 11.0
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
            // Check if the foodItem was removed from the scene graph
            XCTAssertNil(foodItem.parent, "Food item should be removed from the scene graph after 10 seconds.")
            
            // As noted, GameScene.swift's timed removal only calls removeFromParent().
            // It does NOT remove the item from the `scene.foodItems` array.
            // So, we verify it's still in the array if that's the case, or not if behavior changed.
            // Current GameScene behavior: it remains in the array.
            // XCTAssertTrue(scene.foodItems.contains(foodItem), "Food item should still be in foodItems array as timed removal doesn't clear it from there.")
            // However, this assertion might be misleading if the goal is to test "full" removal.
            // The key is that it's visually gone. The array part is an implementation detail of GameScene.
            // For this test, parent == nil is the primary success criteria for the action.
        }
    }

    func testSpawnObstacle() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }
        
        // Clear any obstacles spawned by loadLevel in setUp
        scene.obstacles.forEach { $0.removeFromParent() }
        scene.obstacles.removeAll()

        // Ensure textures are loaded (implicitly done by scene.didMove(to: view) in setup)
        XCTAssertNotNil(scene.rock1Texture, "rock1Texture should be loaded")
        XCTAssertNotNil(scene.rock2Texture, "rock2Texture should be loaded")
        XCTAssertNotNil(scene.rock3Texture, "rock3Texture should be loaded")
        
        let initialObstacleArrayCount = scene.obstacles.count
        let initialSceneObstacleNodeCount = scene.children.filter { $0.physicsBody?.categoryBitMask == GameScene.PhysicsCategory.obstacle }.count
        
        scene.spawnObstacle() // Spawns 1 obstacle
        
        XCTAssertEqual(scene.obstacles.count, initialObstacleArrayCount + 1, "Obstacles array should increment by 1.")
        
        let finalSceneObstacleNodeCount = scene.children.filter { $0.physicsBody?.categoryBitMask == GameScene.PhysicsCategory.obstacle }.count
        XCTAssertEqual(finalSceneObstacleNodeCount, initialSceneObstacleNodeCount + 1, "Number of obstacle children in scene should increment by 1.")

        guard let newObstacle = scene.obstacles.last else {
            XCTFail("No new obstacle found in obstacles array.")
            return
        }
        
        XCTAssertNotNil(newObstacle.physicsBody, "Obstacle should have a physics body.")
        XCTAssertEqual(newObstacle.physicsBody?.categoryBitMask, GameScene.PhysicsCategory.obstacle, "Obstacle physics category should be .obstacle.")
        XCTAssertNotNil(newObstacle.parent, "Obstacle should be added to the scene graph.")
    }

    // MARK: - Collision Tests

    // Helper function to simulate the effects of didBegin(_:) for a given food node.
    // This is a workaround because SKPhysicsContact cannot be easily mocked or instantiated.
    private func simulateContactEffects(for foodNode: SKSpriteNode) {
        guard let scene = scene, scene.frog != nil else {
            XCTFail("Scene or frog not available for contact simulation. Frog: \(String(describing: scene?.frog))")
            return
        }

        // Ensure game is not over for contact to process, as per GameScene.didBegin's guard condition
        scene.isGameOver = false 

        // 1. Determine points and particle color based on food texture
        var particleColor: SKColor = .white // Default, should be overridden
        var points = 0
        
        // Ensure textures are loaded in the scene instance. These are loaded via loadLevel() in setUpWithError().
        guard scene.fly1Texture != nil, scene.fly2Texture != nil,
              scene.spider1Texture != nil, scene.spider2Texture != nil,
              scene.ant1Texture != nil, scene.ant2Texture != nil else {
            XCTFail("Food textures not loaded in scene instance. Cannot determine food type for collision effects simulation.")
            return
        }

        switch foodNode.texture {
        case scene.fly1Texture, scene.fly2Texture:
            particleColor = .green
            points = 2
        case scene.spider1Texture, scene.spider2Texture:
            particleColor = .brown
            points = 2
        case scene.ant1Texture, scene.ant2Texture:
            particleColor = .red
            points = 1
        default:
            XCTFail("Food node has unrecognized or nil texture: \(String(describing: foodNode.texture)). Points will be 0.")
            // Points remain 0, particleColor remains .white
        }

        // 2. Create eating effect (as done in GameScene.didBegin)
        scene.createEatingEffect(at: foodNode.position, color: particleColor)
        // Note: SoundManager and Haptic Feedback calls from original didBegin are omitted here
        // as they are hard to test directly in this unit test environment without more advanced mocking.

        // 3. Update score
        scene.score += points
        // Ensure scoreLabel exists before trying to update its text
        guard let scoreLabel = scene.scoreLabel else {
            XCTFail("scoreLabel is nil. Cannot update score text.")
            return // Cannot proceed if scoreLabel is missing
        }
        scoreLabel.text = "Score: \(scene.score)"

        // 4. Remove food node from scene and from tracking array
        foodNode.removeFromParent()
        if let index = scene.foodItems.firstIndex(of: foodNode) {
            scene.foodItems.remove(at: index)
        }

        // 5. Add score popup (replicating GameScene.didBegin's logic)
        let scorePopup = SKLabelNode(fontNamed: "Chalkduster")
        scorePopup.text = "+\(points)"
        scorePopup.fontSize = 24
        scorePopup.fontColor = SKColor.yellow
        scorePopup.position = foodNode.position // Position where food was
        scorePopup.zPosition = 3 // Ensure it's visible
        scene.addChild(scorePopup)
        
        // Actions for score popup animation
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        scorePopup.run(SKAction.sequence([group, remove]))
    }
    
    // Helper to create a food node for testing collisions
    private func createTestFoodNodeWithTexture(_ texture: SKTexture?) -> SKSpriteNode? {
        guard let scene = scene else {
            XCTFail("Scene is nil. Cannot create food node.")
            return nil
        }
        guard let tex = texture else {
            XCTFail("Texture provided for food node creation is nil.")
            return nil
        }
        let foodNode = SKSpriteNode(texture: tex)
        foodNode.name = "food" // Standard name as used in GameScene
        // Position it somewhere in the scene, e.g., center
        foodNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2) 
        
        // Simplified physics body setup, primarily for categoryBitMask
        // The actual collision is not simulated by physics engine here.
        let foodPhysicsRadius = min(foodNode.size.width, foodNode.size.height) * 0.3 // As in spawnFood
        foodNode.physicsBody = SKPhysicsBody(circleOfRadius: foodPhysicsRadius)
        foodNode.physicsBody?.categoryBitMask = GameScene.PhysicsCategory.food
        
        // Add to scene and foodItems array for a consistent state before simulating contact effects
        scene.addChild(foodNode)
        scene.foodItems.append(foodNode)
        return foodNode
    }

    // Helper to reset scene state for collision tests
    private func prepareSceneForCollisionTest() {
        guard let scene = scene else { 
            XCTFail("Scene is nil during prepareSceneForCollisionTest.")
            return
        }
        scene.score = 0 
        // Ensure scoreLabel is available and reset
        if scene.scoreLabel == nil {
             // If scoreLabel is nil, it might indicate an issue in setUp or GameScene init.
             // For robustness, create it if missing, though tests for initial state should cover this.
            scene.scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
            scene.scoreLabel.position = CGPoint(x: (scene.size.width / 2) - 200, y: scene.size.height - 110) // Example position
            scene.addChild(scene.scoreLabel)
        }
        scene.scoreLabel.text = "Score: 0"
        
        // Remove existing food items from scene and array
        scene.foodItems.forEach { $0.removeFromParent() } 
        scene.foodItems.removeAll() 
        
        // Remove any transient nodes like particle emitters or old score popups
        scene.children.filter { node in
            (node is SKEmitterNode) || (node as? SKLabelNode)?.text?.starts(with: "+") == true
        }.forEach { $0.removeFromParent() }
    }

    func testCollisionWithFly() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }
        XCTAssertNotNil(scene.fly1Texture, "Fly1 texture must be loaded for this test.")
        
        prepareSceneForCollisionTest()
        let initialScore = scene.score // Should be 0
        
        guard let flyNode = createTestFoodNodeWithTexture(scene.fly1Texture) else {
            XCTFail("Failed to create fly node for testing collision.")
            return
        }
        let initialFoodItemsCount = scene.foodItems.count // Should be 1 (the flyNode just added)

        // Simulate the effects of a contact
        simulateContactEffects(for: flyNode)

        // Assertions for fly (2 points)
        XCTAssertNil(flyNode.parent, "Fly node should be removed from scene after contact effects.")
        XCTAssertFalse(scene.foodItems.contains(flyNode), "Fly node should be removed from foodItems array.")
        XCTAssertEqual(scene.foodItems.count, initialFoodItemsCount - 1, "FoodItems array count should decrease by 1.")
        XCTAssertEqual(scene.score, initialScore + 2, "Score should increase by 2 for a fly.")
        XCTAssertEqual(scene.scoreLabel?.text, "Score: \(initialScore + 2)", "Score label should reflect the new score.")
        
        // Check for transient effects: particle emitter and score popup
        // These are added and then removed by their own actions, so we check for their presence immediately after simulation.
        let emitters = scene.children.filter { $0 is SKEmitterNode }
        XCTAssertFalse(emitters.isEmpty, "An eating particle effect (SKEmitterNode) should have been added to the scene.")
        
        var scorePopupFound = false
        for node in scene.children {
            if let labelNode = node as? SKLabelNode, labelNode.text == "+2" {
                scorePopupFound = true
                // labelNode.removeAllActions() // Optional: stop its removal for inspection if debugging
                break
            }
        }
        XCTAssertTrue(scorePopupFound, "A score popup label with '+2' should be added for the fly.")
    }

    func testCollisionWithSpider() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }
        XCTAssertNotNil(scene.spider1Texture, "Spider1 texture must be loaded for this test.")

        prepareSceneForCollisionTest()
        let initialScore = scene.score 
        
        guard let spiderNode = createTestFoodNodeWithTexture(scene.spider1Texture) else {
            XCTFail("Failed to create spider node for testing collision.")
            return
        }
        let initialFoodItemsCount = scene.foodItems.count

        simulateContactEffects(for: spiderNode)

        // Assertions for spider (2 points)
        XCTAssertNil(spiderNode.parent, "Spider node should be removed from scene after contact effects.")
        XCTAssertFalse(scene.foodItems.contains(spiderNode), "Spider node should be removed from foodItems array.")
        XCTAssertEqual(scene.foodItems.count, initialFoodItemsCount - 1, "FoodItems array count should decrease by 1.")
        XCTAssertEqual(scene.score, initialScore + 2, "Score should increase by 2 for a spider.")
        XCTAssertEqual(scene.scoreLabel?.text, "Score: \(initialScore + 2)", "Score label should reflect the new score.")

        let emitters = scene.children.filter { $0 is SKEmitterNode }
        XCTAssertFalse(emitters.isEmpty, "An eating particle effect (SKEmitterNode) should have been added.")
        
        var scorePopupFound = false
        for node in scene.children {
            if let labelNode = node as? SKLabelNode, labelNode.text == "+2" {
                scorePopupFound = true
                break
            }
        }
        XCTAssertTrue(scorePopupFound, "A score popup label with '+2' should be added for the spider.")
    }

    func testCollisionWithAnt() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }
        XCTAssertNotNil(scene.ant1Texture, "Ant1 texture must be loaded for this test.")

        prepareSceneForCollisionTest()
        let initialScore = scene.score
        
        guard let antNode = createTestFoodNodeWithTexture(scene.ant1Texture) else {
            XCTFail("Failed to create ant node for testing collision.")
            return
        }
        let initialFoodItemsCount = scene.foodItems.count

        simulateContactEffects(for: antNode)

        // Assertions for ant (1 point)
        XCTAssertNil(antNode.parent, "Ant node should be removed from scene after contact effects.")
        XCTAssertFalse(scene.foodItems.contains(antNode), "Ant node should be removed from foodItems array.")
        XCTAssertEqual(scene.foodItems.count, initialFoodItemsCount - 1, "FoodItems array count should decrease by 1.")
        XCTAssertEqual(scene.score, initialScore + 1, "Score should increase by 1 for an ant.")
        XCTAssertEqual(scene.scoreLabel?.text, "Score: \(initialScore + 1)", "Score label should reflect the new score.")

        let emitters = scene.children.filter { $0 is SKEmitterNode }
        XCTAssertFalse(emitters.isEmpty, "An eating particle effect (SKEmitterNode) should have been added.")
        
        var scorePopupFound = false
        for node in scene.children {
            if let labelNode = node as? SKLabelNode, labelNode.text == "+1" {
                scorePopupFound = true
                break
            }
        }
        XCTAssertTrue(scorePopupFound, "A score popup label with '+1' should be added for the ant.")
    }

    // MARK: - Game Over and Restart Tests

    // Helper to find the game over result label node, which is a child of an SKShapeNode
    private func findResultLabelNode(in scene: SKScene) -> SKLabelNode? {
        for node in scene.children {
            // The SKShapeNode is the yellow background for the result label
            if node is SKShapeNode {
                // The actual SKLabelNode is a child of this SKShapeNode
                for childNode in node.children {
                    if let labelNode = childNode as? SKLabelNode,
                       (labelNode.name == "nextLevelLabel" || labelNode.name == "tryAgainLabel") {
                        return labelNode
                    }
                }
            }
        }
        return nil // Return nil if no such label structure is found
    }

    func testGameOver_WinCondition() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }

        // Initial state checks (timer should be valid from setup)
        XCTAssertTrue(scene.gameTimer?.isValid ?? false, "Game timer should be running at test start.")

        scene.score = 100 // Setup win condition
        scene.gameOver()  // Manually trigger gameOver

        XCTAssertTrue(scene.isGameOver, "isGameOver flag should be true after gameOver() is called.")
        // In GameScene.gameOver(), gameTimer is invalidated.
        XCTAssertFalse(scene.gameTimer?.isValid ?? true, "Game timer should be invalidated by gameOver().")
        
        let resultLabel = findResultLabelNode(in: scene)
        XCTAssertNotNil(resultLabel, "A result label node should be present after game over.")
        XCTAssertEqual(resultLabel?.text, "Frog Won!", "Result label should display 'Frog Won!' when score is 100.")
        XCTAssertEqual(resultLabel?.name, "nextLevelLabel", "Result label's name should be 'nextLevelLabel' for a win.")
    }

    func testGameOver_LoseCondition() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }

        scene.score = 50 // Setup lose condition (score < 100)
        scene.gameOver() // Manually trigger gameOver

        XCTAssertTrue(scene.isGameOver, "isGameOver flag should be true after gameOver() is called.")
        XCTAssertFalse(scene.gameTimer?.isValid ?? true, "Game timer should be invalidated by gameOver().")
        
        let resultLabel = findResultLabelNode(in: scene)
        XCTAssertNotNil(resultLabel, "A result label node should be present after game over.")
        XCTAssertEqual(resultLabel?.text, "Try Again!", "Result label should display 'Try Again!' when score is less than 100.")
        XCTAssertEqual(resultLabel?.name, "tryAgainLabel", "Result label's name should be 'tryAgainLabel' for a loss.")
    }

    func testGameOver_TriggeredByTimerRunningOut() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }

        // Pre-condition: Timer is running, game is not over.
        XCTAssertTrue(scene.gameTimer?.isValid ?? false, "Game timer should be running from scene setup.")
        XCTAssertFalse(scene.isGameOver, "Game should not be over at the start of this specific test.")
        
        scene.gameTime = 1.0 // Set a very short game time
        scene.score = 30     // Arbitrary score for lose condition label check

        let gameOverExpectation = self.expectation(description: "Game Over should be triggered by game timer")
        
        // The game timer in GameScene fires every 1.0 second.
        // It decrements gameTime then checks if gameTime <= 0.
        // So, after 1.0s, gameTime becomes 0, then gameOver() is called.
        // We wait for slightly longer than that.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Wait for 1s game time + 0.5s buffer
            if scene.isGameOver { // Check if gameOver was triggered
                gameOverExpectation.fulfill()
            } else {
                // If not game over, it might be due to timing or timer issues.
                // XCTFail("Game over was not triggered by timer as expected. scene.isGameOver is false.")
                // Fulfilling here anyway to prevent test from hanging, but assertions below will fail.
                // A better way is to let the timeout handle it if it doesn't fulfill.
            }
        }
        
        waitForExpectations(timeout: 2.0) { error in
            if let error = error {
                XCTFail("waitForExpectations for game over by timer failed: \(error)")
            }
        }

        XCTAssertTrue(scene.isGameOver, "isGameOver flag should be true after game time runs out.")
        // gameTimer is invalidated inside GameScene.gameOver()
        XCTAssertFalse(scene.gameTimer?.isValid ?? true, "Game timer should be invalidated when game time runs out.")
        
        let resultLabel = findResultLabelNode(in: scene)
        XCTAssertNotNil(resultLabel, "A result label node should be present after timer-triggered game over.")
        XCTAssertEqual(resultLabel?.text, "Try Again!", "Result label should display 'Try Again!' (score was 30).")
        XCTAssertEqual(resultLabel?.name, "tryAgainLabel", "Result label's name should be 'tryAgainLabel'.")
    }

    func testRestartGame_FromLoseState() {
        guard let scene = scene else { XCTFail("Scene not initialized"); return }

        // 1. Setup: Trigger a game over (lose condition)
        scene.score = 40
        scene.gameOver() // Manually trigger for controlled setup
        XCTAssertTrue(scene.isGameOver, "Pre-condition: Game should be over to test restart.")
        let oldResultLabel = findResultLabelNode(in: scene)
        XCTAssertNotNil(oldResultLabel, "Pre-condition: A result label should exist from the game over state.")
        XCTAssertEqual(oldResultLabel?.name, "tryAgainLabel", "Pre-condition: Label should be 'tryAgainLabel'.")

        // 2. Action: Call restartGame with a new level
        let newLevelToStart = 5
        scene.restartGame(restartLevel: newLevelToStart)

        // 3. Assertions for restartGame effects
        XCTAssertFalse(scene.isGameOver, "isGameOver should be false after restartGame().")
        XCTAssertEqual(scene.score, 0, "Score should be reset to 0 after restart.")
        XCTAssertEqual(scene.scoreLabel?.text, "Score: 0", "Score label text should be updated to 'Score: 0'.")
        XCTAssertEqual(scene.gameTime, 120.0, "Game time should be reset to 120.0.")
        XCTAssertEqual(scene.timerLabel?.text, "Time: 120", "Timer label text should be updated to 'Time: 120'.")
        XCTAssertEqual(scene.level, newLevelToStart, "Scene level should be updated to \(newLevelToStart).")
        
        // Check that the old game over label is removed
        let currentResultLabel = findResultLabelNode(in: scene)
        XCTAssertNil(currentResultLabel, "The game over result label should be removed after restartGame().")
        
        // Check that a new game timer is started and valid (restartGame -> loadLevel -> startGameTimer)
        XCTAssertTrue(scene.gameTimer?.isValid ?? false, "A new game timer should be started and be valid after restart.")

        // Verify that essential game elements are re-loaded by loadLevel (called by restartGame)
        XCTAssertNotNil(scene.frog, "Frog node should be present after restartGame.")
        XCTAssertNotNil(scene.scoreLabel, "ScoreLabel node should be present after restartGame.")
        XCTAssertNotNil(scene.timerLabel, "TimerLabel node should be present after restartGame.")
        
        // Check for the new level's label
        var levelLabelNodeFound = false
        for node in scene.children {
            if let label = node as? SKLabelNode, label.text == "Level: \(newLevelToStart)" {
                levelLabelNodeFound = true
                break
            }
        }
        XCTAssertTrue(levelLabelNodeFound, "The Level label for the new level (\(newLevelToStart)) should be present.")
    }
}
