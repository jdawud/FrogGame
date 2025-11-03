import XCTest
@testable import Froggy_Hopper

final class SoundManagerTests: XCTestCase {

    func testSharedReturnsSingletonInstance() {
        let firstReference = SoundManager.shared
        let secondReference = SoundManager.shared
        XCTAssertTrue(firstReference === secondReference, "SoundManager.shared should always return the same instance.")
    }

    func testStopBackgroundMusicWithoutPlayerDoesNotCrash() {
        let manager = SoundManager()
        manager.audioPlayer = nil

        XCTAssertNoThrow(manager.stopBackgroundMusic())
        XCTAssertNil(manager.audioPlayer)
    }

    func testStopSoundEffectWithoutPlayerDoesNotCrash() {
        let manager = SoundManager()

        XCTAssertNoThrow(manager.stopSoundEffect(named: "missing.mp3"))
        XCTAssertTrue(manager.soundEffects.isEmpty)
    }

    #if canImport(AVFoundation)
    func testStopBackgroundMusicStopsPlayingAudio() {
        let manager = SoundManager()
        let player = StubAudioPlayer()
        _ = player.play()
        manager.audioPlayer = player

        manager.stopBackgroundMusic()

        XCTAssertEqual(player.stopCallCount, 1)
        XCTAssertFalse(player.isPlaying)
    }

    func testStopSoundEffectStopsCachedPlayer() {
        let manager = SoundManager()
        let player = StubAudioPlayer()
        _ = player.play()
        manager.soundEffects["effect.mp3"] = player

        manager.stopSoundEffect(named: "effect.mp3")

        XCTAssertEqual(player.stopCallCount, 1)
        XCTAssertFalse(player.isPlaying)
    }
    #else
    func testAudioSpecificBehaviourRequiresAVFoundation() throws {
        throw XCTSkip("AVFoundation is not available on this platform.")
    }
    #endif
}

#if canImport(AVFoundation)
import AVFoundation

private final class StubAudioPlayer: AVAudioPlayer {
    private var playing = false
    private(set) var stopCallCount = 0
    private var storedCurrentTime: TimeInterval = 0

    override init() {
        super.init()
    }

    override var isPlaying: Bool {
        playing
    }

    override var currentTime: TimeInterval {
        get { storedCurrentTime }
        set { storedCurrentTime = newValue }
    }

    override func play() -> Bool {
        playing = true
        return true
    }

    override func stop() {
        if playing {
            stopCallCount += 1
        }
        playing = false
    }
}
#endif
