//
//  SoundManager.swift
//  Froggy Hopper
//
//  Created by junaid dawud on 6/11/23.
//

/// Singleton audio manager for background music and sound effects.
///
/// Uses AVAudioPlayer to loop background tracks and play one-shot sound effects.
/// Caches sound effect players to avoid overlapping playback of the same sound.

import Foundation
import AVFoundation

class SoundManager {

    static let shared = SoundManager()

    var audioPlayer: AVAudioPlayer?
    var soundEffects = [String: AVAudioPlayer]()

    func playBackgroundMusic(filename: String) {
        let url = Bundle.main.url(forResource: filename, withExtension: nil)
        guard let newURL = url else {
            print("Could not find file: \(filename)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: newURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch let error as NSError {
            print(error.description)
        }
    }

    func stopBackgroundMusic() {
        audioPlayer?.stop()
    }

    func playSoundEffect(named name: String) {
        if let player = soundEffects[name], player.isPlaying {
            player.stop()
            player.currentTime = 0
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            print("Could not find sound file named \(name)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            soundEffects[name] = player
        } catch let error as NSError {
            print(error.description)
        }
    }

    func stopSoundEffect(named name: String) {
        if let player = soundEffects[name], player.isPlaying {
            player.stop()
        }
    }
}
