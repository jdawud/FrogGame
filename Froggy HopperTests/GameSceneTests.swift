import XCTest
import SpriteKit
@testable import Froggy_Hopper

final class GameSceneTests: XCTestCase {

    private var scene: TestGameScene!

    override func setUpWithError() throws {
        try super.setUpWithError()
        scene = TestGameScene(size: CGSize(width: 1024, height: 768))
        scene.prepareForTesting()
    }

    override func tearDownWithError() throws {
        scene = nil
        try super.tearDownWithError()
    }

    func testLoadLevelCreatesCoreNodes() throws {
        XCTAssertNotNil(scene.frog, "The frog node should be created when the level loads.")
        XCTAssertNotNil(scene.scoreLabel, "The score label should be created when the level loads.")
        XCTAssertNotNil(scene.timerLabel, "The timer label should be created when the level loads.")
        XCTAssertEqual(scene.scoreLabel.text, "Score: 0")
        XCTAssertEqual(scene.timerLabel.text, "Time: 120")
        XCTAssertEqual(scene.loadLevelCallCount, 1, "loadLevel should have been called exactly once during setup.")
    }

    func testRestartGameResetsState() throws {
        scene.score = 45
        scene.gameTime = 12
        scene.level = 4
        scene.scoreLabel.text = "Score: 45"
        scene.timerLabel.text = "Time: 12"

        scene.gameOver()
        XCTAssertNotNil(findResultLabel(named: "tryAgainLabel"), "Game over should present a result label before restart.")

        scene.restartGame(restartLevel: 2)

        XCTAssertEqual(scene.level, 2)
        XCTAssertEqual(scene.score, 0)
        XCTAssertEqual(scene.gameTime, 120)
        XCTAssertEqual(scene.scoreLabel.text, "Score: 0")
        XCTAssertEqual(scene.timerLabel.text, "Time: 120")
        XCTAssertNil(findResultLabel(named: "tryAgainLabel"), "Result labels should be removed after restarting the level.")
        XCTAssertEqual(scene.loadLevelCallCount, 2, "Restarting the game should reload the level.")
        XCTAssertFalse(scene.isGameOver, "Restarting the game should clear the game over flag.")
    }

    func testGameOverWinDisplaysNextLevelLabel() throws {
        scene.score = 120

        scene.gameOver()

        XCTAssertTrue(scene.isGameOver)
        let resultLabel = findResultLabel(named: "nextLevelLabel")
        XCTAssertEqual(resultLabel?.text, "Frog Won!")
    }

    func testGameOverLoseDisplaysTryAgainLabel() throws {
        scene.score = 20

        scene.gameOver()

        let resultLabel = findResultLabel(named: "tryAgainLabel")
        XCTAssertEqual(resultLabel?.text, "Try Again!")
    }

    func testPhysicsCategoriesMatchExpectedBitmasks() {
        XCTAssertEqual(GameScene.PhysicsCategory.frog, 0b1)
        XCTAssertEqual(GameScene.PhysicsCategory.food, 0b10)
        XCTAssertEqual(GameScene.PhysicsCategory.obstacle, 0b100)
        XCTAssertEqual(GameScene.PhysicsCategory.none, 0)
    }

    private func findResultLabel(named name: String) -> SKLabelNode? {
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
