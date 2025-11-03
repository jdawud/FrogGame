import Testing
import Foundation
import AVFoundation
@testable import Froggy_Hopper

struct SoundManagerTests {

    @Test
    func sharedReturnsSingletonInstance() {
        let firstReference = SoundManager.shared
        let secondReference = SoundManager.shared
        #expect(firstReference === secondReference, "SoundManager.shared should always return the same instance.")
    }

    @Test
    func stopBackgroundMusicWithoutPlayerDoesNotCrash() {
        let manager = SoundManager()
        manager.audioPlayer = nil

        manager.stopBackgroundMusic()
        #expect(manager.audioPlayer == nil)
    }

    @Test
    func stopSoundEffectWithoutPlayerDoesNotCrash() {
        let manager = SoundManager()

        manager.stopSoundEffect(named: "missing.mp3")
        #expect(manager.soundEffects.isEmpty)
    }

    @Test
    func stopBackgroundMusicStopsPlayingAudio() throws {
        let manager = SoundManager()
        let url = try #require(Bundle.main.url(forResource: "BackgroundMusic1", withExtension: "mp3"))
        let player = try AVAudioPlayer(contentsOf: url)
        _ = player.play()
        manager.audioPlayer = player

        manager.stopBackgroundMusic()

        #expect(player.isPlaying == false)
    }

    @Test
    func stopSoundEffectStopsCachedPlayer() throws {
        let manager = SoundManager()
        let url = try #require(Bundle.main.url(forResource: "eat_sound", withExtension: "mp3"))
        let player = try AVAudioPlayer(contentsOf: url)
        _ = player.play()
        manager.soundEffects["eat_sound.mp3"] = player

        manager.stopSoundEffect(named: "eat_sound.mp3")

        #expect(player.isPlaying == false)
    }
}

// No stub needed: tests use real AVAudioPlayer constructed from bundled resources.
