import XCTest
import AVFoundation
@testable import Froggy_Hopper

class SoundManagerTests: XCTestCase {

    var soundManager: SoundManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        soundManager = SoundManager.shared // Using the singleton instance
    }

    override func tearDownWithError() throws {
        soundManager.stopBackgroundMusic() // For background music
        // Stop all sound effects and clear the dictionary
        for player in soundManager.soundEffects.values {
            player.stop()
        }
        soundManager.soundEffects.removeAll()
        soundManager = nil
        try super.tearDownWithError()
    }

    // Test playing a valid background music file
    func testPlayBackgroundMusic_ValidFile() {
        // Ensure no music is playing initially from a previous (failed) test or state
        soundManager.stopBackgroundMusic()
        soundManager.audioPlayer = nil // Reset state

        let validFilename = "BackgroundMusic1.mp3"
        soundManager.playBackgroundMusic(filename: validFilename)

        XCTAssertNotNil(soundManager.audioPlayer, "Audio player should be initialized for a valid file.")
        XCTAssertTrue(soundManager.audioPlayer?.isPlaying ?? false, "Audio player should be playing the valid file.")
        XCTAssertEqual(soundManager.audioPlayer?.numberOfLoops, -1, "Background music should loop indefinitely.")
        
        // Check if the URL of the playing item matches the filename
        // This confirms the correct file is loaded.
        XCTAssertEqual(soundManager.audioPlayer?.url?.lastPathComponent, validFilename, "The correct music file should be loaded.")
    }

    // Test stopping background music
    func testStopBackgroundMusic() {
        let validFilename = "BackgroundMusic1.mp3"
        soundManager.playBackgroundMusic(filename: validFilename)
        
        // Pre-condition: ensure music is playing
        XCTAssertTrue(soundManager.audioPlayer?.isPlaying ?? false, "Audio player should be playing before stop is called.")

        soundManager.stopBackgroundMusic()
        XCTAssertFalse(soundManager.audioPlayer?.isPlaying ?? false, "Audio player should not be playing after stopBackgroundMusic() is called.")
    }

    // Test playing background music with an invalid filename
    func testPlayBackgroundMusic_InvalidFile() {
        // Ensure audioPlayer is in a known state (nil) before this test
        soundManager.stopBackgroundMusic() 
        let initialPlayer = soundManager.audioPlayer // Could be nil or an existing player instance
        let initialPlayerURL = initialPlayer?.url // Store URL if player exists

        let invalidFilename = "NonExistentFile.mp3"
        soundManager.playBackgroundMusic(filename: invalidFilename)
        
        // SoundManager's current implementation: if url for new music is nil, it prints an error and returns early.
        // This means the `self.audioPlayer` instance is not reassigned or stopped if it was already playing.
        if let preExistingPlayer = initialPlayer {
            // If a player was existing and playing, it should still be the same player and playing the same URL.
            XCTAssertTrue(soundManager.audioPlayer === preExistingPlayer, "AudioPlayer instance should not have changed if new file is invalid and old player existed.")
            XCTAssertEqual(soundManager.audioPlayer?.url, initialPlayerURL, "AudioPlayer should still be configured with the old URL if new one is invalid.")
            // Its isPlaying state would also be unchanged.
        } else {
            // If audioPlayer was nil initially, it should remain nil.
            XCTAssertNil(soundManager.audioPlayer, "Audio player should remain nil if it was nil and an invalid file was attempted.")
        }
    }
    
    // Test that playing a new background music stops/replaces the previous one
    func testPlayBackgroundMusic_ReplacesPreviousMusic() {
        let firstSong = "BackgroundMusic1.mp3"
        let secondSong = "BackgroundMusic2.mp3" // Assuming this is another valid file

        // Play the first song
        soundManager.playBackgroundMusic(filename: firstSong)
        XCTAssertTrue(soundManager.audioPlayer?.isPlaying ?? false, "First song should be playing.")
        XCTAssertEqual(soundManager.audioPlayer?.url?.lastPathComponent, firstSong, "First song (BackgroundMusic1.mp3) should be loaded.")
        // Let firstPlayerInstance = soundManager.audioPlayer // Not needed due to instance reuse

        // Play the second song
        soundManager.playBackgroundMusic(filename: secondSong)
        XCTAssertTrue(soundManager.audioPlayer?.isPlaying ?? false, "Second song should now be playing.")
        XCTAssertEqual(soundManager.audioPlayer?.url?.lastPathComponent, secondSong, "Second song (BackgroundMusic2.mp3) should be loaded, replacing the first.")

        // Since SoundManager reuses the `audioPlayer` instance variable, the instance itself might be the same
        // but its `url` property will have changed to the new song.
        // The key checks are that it's playing and the URL points to the second song.
    }

    // MARK: - Sound Effect Tests

    // Test playing a valid sound effect file
    func testPlaySoundEffect_ValidFile() {
        let effectName = "eat_sound.mp3"
        // Ensure the sound effect is not already in the dictionary from a previous (failed) test
        soundManager.soundEffects[effectName]?.stop()
        soundManager.soundEffects.removeValue(forKey: effectName)

        soundManager.playSoundEffect(named: effectName)

        let player = soundManager.soundEffects[effectName]
        XCTAssertNotNil(player, "Sound effect player should be created for a valid file.")
        XCTAssertTrue(player?.isPlaying ?? false, "Sound effect should be playing.")
        XCTAssertEqual(player?.url?.lastPathComponent, effectName, "Correct sound effect file should be loaded.")
    }

    // Test that re-playing a sound effect stops the current instance and starts a new one
    func testPlaySoundEffect_RestartIfAlreadyPlaying() {
        let effectName = "eat_sound.mp3"

        // Play it once
        soundManager.playSoundEffect(named: effectName)
        guard let player1 = soundManager.soundEffects[effectName] else {
            XCTFail("Player for \(effectName) was not created on first play.")
            return
        }
        XCTAssertTrue(player1.isPlaying, "Sound effect should be playing after first call.")
        let initialPlayer1CurrentTime = player1.currentTime // Store initial time

        // Wait for a very short interval to ensure currentTime might advance if playing
        // This helps make the check for player1.currentTime reset more robust.
        // However, system timing for audio can be tricky in unit tests.
        // A more direct check is that player1.isPlaying becomes false.
        let expectation = self.expectation(description: "Short delay for sound effect to play a bit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)


        // Play it again immediately
        soundManager.playSoundEffect(named: effectName)
        
        // The original player1 instance should have been stopped.
        XCTAssertFalse(player1.isPlaying, "The first player instance (player1) should be stopped after re-playing the same sound effect.")
        // And its time should have been reset by the SoundManager logic: player.currentTime = 0
        // This check relies on player1 instance still being the one we have a reference to,
        // and not immediately deallocated if SoundManager reuses the dictionary key quickly.
        // Given ARC, player1 reference here keeps it alive for this check.
        XCTAssertEqual(player1.currentTime, 0, "Player1's currentTime should be reset to 0.")


        guard let player2 = soundManager.soundEffects[effectName] else {
            XCTFail("Player for \(effectName) was not found in dictionary after second play.")
            return
        }
        XCTAssertTrue(player2.isPlaying, "New sound effect instance (player2) should be playing after second call.")
        // As per SoundManager logic, a *new* AVAudioPlayer instance is created.
        XCTAssertNotIdentical(player1, player2, "A new player instance (player2) should have been created for the second play.")
    }

    // Test stopping a sound effect
    func testStopSoundEffect() {
        let effectName = "eat_sound.mp3"
        soundManager.playSoundEffect(named: effectName)

        guard let player = soundManager.soundEffects[effectName] else {
            XCTFail("Player for \(effectName) was not created, cannot test stop.")
            return
        }
        // Ensure it's playing before we stop it
        XCTAssertTrue(player.isPlaying, "Sound effect should be playing before stop is called.")

        soundManager.stopSoundEffect(named: effectName)
        XCTAssertFalse(player.isPlaying, "Sound effect should not be playing after stopSoundEffect() is called.")
    }

    // Test playing a sound effect with an invalid filename
    func testPlaySoundEffect_InvalidFile() {
        let invalidEffectName = "NonExistentEffect.mp3"
        // Ensure it's not in the dictionary from a previous test
        soundManager.soundEffects.removeValue(forKey: invalidEffectName)

        soundManager.playSoundEffect(named: invalidEffectName)

        // SoundManager prints an error and returns if URL is nil. No player is added to soundEffects.
        XCTAssertNil(soundManager.soundEffects[invalidEffectName], "No player should be added to soundEffects dictionary for an invalid file.")
    }
}
