import Testing
import SpriteKit
@testable import Froggy_Hopper

struct GameSceneTests {

    @Test
    func loadLevelCreatesCoreNodes() {
        let scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()

        #expect(scene.frog != nil, "The frog node should be created when the level loads.")
        #expect(scene.scoreLabel != nil, "The score label should be created when the level loads.")
        #expect(scene.timerLabel != nil, "The timer label should be created when the level loads.")
        #expect(scene.scoreLabel.text == "Score: 0")
        #expect(scene.timerLabel.text == "Time: 120")
        #expect(scene.loadLevelCallCount == 1, "loadLevel should have been called exactly once during setup.")
    }

    @Test
    func restartGameResetsState() {
        let scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()

        scene.score = 45
        scene.gameTime = 12
        scene.level = 4
        scene.scoreLabel.text = "Score: 45"
        scene.timerLabel.text = "Time: 12"

        scene.gameOver()
        #expect(findResultLabel(in: scene, named: "tryAgainLabel") != nil, "Game over should present a result label before restart.")

        scene.restartGame(restartLevel: 2)

        #expect(scene.level == 2)
        #expect(scene.score == 0)
        #expect(scene.gameTime == 120)
        #expect(scene.scoreLabel.text == "Score: 0")
        #expect(scene.timerLabel.text == "Time: 120")
        #expect(findResultLabel(in: scene, named: "tryAgainLabel") == nil, "Result labels should be removed after restarting the level.")
        #expect(scene.loadLevelCallCount == 2, "Restarting the game should reload the level.")
        #expect(scene.isGameOver == false, "Restarting the game should clear the game over flag.")
    }

    @Test
    func gameOverWinDisplaysNextLevelLabel() {
        let scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()
        scene.score = 120

        scene.gameOver()

        #expect(scene.isGameOver)
        let resultLabel = findResultLabel(in: scene, named: "nextLevelLabel")
        #expect(resultLabel?.text == "Frog Won!")
    }

    @Test
    func gameOverLoseDisplaysTryAgainLabel() {
        let scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()
        scene.score = 20

        scene.gameOver()

        let resultLabel = findResultLabel(in: scene, named: "tryAgainLabel")
        #expect(resultLabel?.text == "Try Again!")
    }

    @Test
    func physicsCategoriesMatchExpectedBitmasks() {
        #expect(GameScene.PhysicsCategory.frog == 0b1)
        #expect(GameScene.PhysicsCategory.food == 0b10)
        #expect(GameScene.PhysicsCategory.obstacle == 0b100)
        #expect(GameScene.PhysicsCategory.none == 0)
    }

    @Test
    func spawnFoodAddsItemsWithCorrectPhysics() {
        let scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()

        let initialCount = scene.foodItems.count
        scene.spawnFood()
        #expect(scene.foodItems.count > initialCount)

        // Check a sample item
        let sample = scene.foodItems.last
        #expect(sample != nil)
        #expect(sample?.physicsBody?.categoryBitMask == GameScene.PhysicsCategory.food)
        #expect(sample?.physicsBody?.contactTestBitMask == GameScene.PhysicsCategory.frog)
        #expect(sample?.physicsBody?.collisionBitMask == GameScene.PhysicsCategory.none)
    }

    @Test
    func spawnObstacleAddsObstaclesWithCorrectPhysics() {
        let scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()

        let initialCount = scene.obstacles.count
        scene.spawnObstacle()
        #expect(scene.obstacles.count == initialCount + 1)

        let sample = scene.obstacles.last
        #expect(sample != nil)
        #expect(sample?.physicsBody?.isDynamic == false)
        #expect(sample?.physicsBody?.affectedByGravity == false)
        #expect(sample?.physicsBody?.categoryBitMask == GameScene.PhysicsCategory.obstacle)
        #expect(sample?.physicsBody?.collisionBitMask == GameScene.PhysicsCategory.none)
    }

    private func findResultLabel(in scene: SKNode, named name: String) -> SKLabelNode? {
        for node in scene.children {
            for child in node.children {
                if let label = child as? SKLabelNode, label.name == name {
                    return label
                }
            }
            if let label = node as? SKLabelNode, label.name == name {
                return label
            }
        }
        return nil
    }
}

private final class TestGameScene: GameScene {

    private(set) var loadLevelCallCount = 0

    func prepareForTesting() {
        scaleMode = .aspectFill
        score = 0
        level = 1
        gameTime = 120
        // Initialize textures used by spawnFood/spawnObstacle
        fly1Texture = SKTexture(imageNamed: "fly1")
        fly2Texture = SKTexture(imageNamed: "fly2")
        spider1Texture = SKTexture(imageNamed: "spider1")
        spider2Texture = SKTexture(imageNamed: "spider2")
        ant1Texture = SKTexture(imageNamed: "ant1")
        ant2Texture = SKTexture(imageNamed: "ant2")
        rock1Texture = SKTexture(imageNamed: "rock1")
        rock2Texture = SKTexture(imageNamed: "rock2")
        rock3Texture = SKTexture(imageNamed: "rock3")
        loadLevel()
    }

    override func loadLevel() {
        loadLevelCallCount += 1

        removeAllChildren()
        foodItems.removeAll()
        obstacles.removeAll()

        frog = SKSpriteNode(color: .green, size: CGSize(width: 48, height: 48))
        frog.position = CGPoint(x: size.width / 2, y: size.height / 4)
        frog.physicsBody = SKPhysicsBody(circleOfRadius: 18)
        frog.physicsBody?.categoryBitMask = PhysicsCategory.frog
        frog.physicsBody?.contactTestBitMask = PhysicsCategory.food
        frog.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(frog)

        scoreLabel = SKLabelNode(fontNamed: "TestFont")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.position = CGPoint(x: size.width / 2 - 200, y: size.height - 110)
        addChild(scoreLabel)

        timerLabel = SKLabelNode(fontNamed: "TestFont")
        timerLabel.text = "Time: \(Int(gameTime))"
        timerLabel.position = CGPoint(x: size.width / 2 + 200, y: size.height - 110)
        addChild(timerLabel)
    }

    override func startGameTimer() {
        gameTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(dummyTimerFire), userInfo: nil, repeats: false)
    }

    @objc private func dummyTimerFire() {}
}
