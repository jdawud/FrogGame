import Testing
import SpriteKit
@testable import Froggy_Hopper

struct WelcomeSceneTests {

    @Test
    func welcomeSceneBuildsKeyUI() {
        let size = CGSize(width: 1024, height: 768)
        let scene = WelcomeScene(size: size)
        let skView = SKView(frame: CGRect(origin: .zero, size: size))
        skView.presentScene(scene)
        scene.scaleMode = .aspectFill
        scene.didMove(to: skView)

        // Title and subtitle labels
        #expect(scene.children.contains { ($0 as? SKLabelNode)?.text == "Froggy Feed!" })
        #expect(scene.children.contains { ($0 as? SKLabelNode)?.text == "Eat bugs, get points!" })

        // Start button pieces are named "startButton"
        let nodesNamedStart = scene.children.flatMap { [$0] + $0.children }.filter { $0.name == "startButton" }
        #expect(!nodesNamedStart.isEmpty)
    }
}

