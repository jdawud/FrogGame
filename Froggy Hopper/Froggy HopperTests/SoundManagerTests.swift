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

    @Test
    func playBackgroundMusicPlaysValidFile() {
        let manager = SoundManager()
        manager.playBackgroundMusic(filename: "BackgroundMusic1.mp3")
        #expect(manager.audioPlayer != nil)
        #expect(manager.audioPlayer?.numberOfLoops == -1)
    }

    @Test
    func playBackgroundMusicMissingFileDoesNotSetPlayer() {
        let manager = SoundManager()
        manager.audioPlayer = nil
        manager.playBackgroundMusic(filename: "missing.mp3")
        #expect(manager.audioPlayer == nil)
    }

    @Test
    func playSoundEffectCachesAndResetsIfAlreadyPlaying() throws {
        let manager = SoundManager()
        manager.playSoundEffect(named: "eat_sound.mp3")
        let first = try #require(manager.soundEffects["eat_sound.mp3"])
        first.currentTime = 0.42
        manager.playSoundEffect(named: "eat_sound.mp3")
        #expect(first.isPlaying == false)
        #expect(first.currentTime == 0)
        let current = try #require(manager.soundEffects["eat_sound.mp3"])
        #expect(current.isPlaying)
    }

    @Test
    func stopSoundEffectIsIdempotent() throws {
        let manager = SoundManager()
        manager.playSoundEffect(named: "eat_sound.mp3")
        let cached = try #require(manager.soundEffects["eat_sound.mp3"])
        manager.stopSoundEffect(named: "eat_sound.mp3")
        #expect(cached.isPlaying == false)
        manager.stopSoundEffect(named: "eat_sound.mp3")
        #expect(cached.isPlaying == false)
    }
}
