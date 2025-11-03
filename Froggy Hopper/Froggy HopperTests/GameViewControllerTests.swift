import Testing
import UIKit
import SpriteKit
@testable import Froggy_Hopper

@MainActor
struct GameViewControllerTests {

    @Test
    func presentsWelcomeSceneOnLoad() {
        let vc = GameViewController()
        // Provide an SKView and invoke viewDidLoad to trigger scene presentation
        vc.view = SKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        vc.viewDidLoad()

        let skView = vc.view as? SKView
        #expect(skView != nil)
        #expect(skView?.scene is WelcomeScene)
    }

    @Test
    func supportedOrientationsAreLandscape() {
        let vc = GameViewController()
        let mask = vc.supportedInterfaceOrientations
        #expect(mask == .landscape)
    }

    @Test
    func prefersStatusBarHiddenIsTrue() {
        let vc = GameViewController()
        #expect(vc.prefersStatusBarHidden == true)
    }
}
