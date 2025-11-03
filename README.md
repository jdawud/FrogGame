# Froggy Hopper 🐸

Froggy Hopper is a simple SpriteKit experiment that follows a hungry frog as it hops around a jungle clearing to snack on insects. The project demonstrates how to build a lightweight iOS arcade scene in Swift with touch controls, basic physics, audio, and haptic feedback. All code targets iOS 13+ and is organised as a standard Xcode project.

## 🎮 Gameplay overview
- **Tap-to-hop controls** – Touch anywhere on the screen to launch the frog in that direction. The frog automatically mirrors to face the hop direction and shortens its jump when a rock blocks the path.
- **Collectible bugs** – Flies, spiders, and ants spawn around the clearing. Each type uses a different texture, scale, and point value, and despawns automatically if ignored.
- **Static obstacles** – Rocks appear at random locations during level loading and are used for hop-shortening collision checks.
- **Timer and scoring UI** – Heads-up display shows the remaining time (starting at 120 seconds), the current level, and the total score.
- **Simple level progression** – Clearing a level (reaching the target score before time expires) unlocks the next stage, swapping in a new background texture and background music track from the bundled set of ten.
- **Welcoming title screen** – A custom Welcome scene handles the start button animation, looping background music, and ambient fly sprites before presenting the game scene.
- **Audio & haptics** – Background music and bite sound effects are managed by `SoundManager`, and successful bites trigger a medium-impact haptic pulse.

## 🏆 Scoring
| Action              | Points |
|---------------------|--------|
| Eat fly (green)     | +2     |
| Eat spider (brown)  | +2     |
| Eat ant (red)       | +1     |

- **Win condition**: Reach 100 points before the 120-second timer reaches zero.
- **Try again**: If time runs out before hitting the target score, the scene resets and keeps you on the current level.

## 🛠️ Project structure
```
Froggy Hopper/
├── AppDelegate.swift / SceneDelegate.swift
├── GameViewController.swift        # Presents the welcome screen
├── WelcomeScene.swift              # Animated start screen with Start button
├── GameScene.swift                 # Core gameplay loop, spawning, and scoring
├── SoundManager.swift              # Background music & sound effect helper
├── Assets.xcassets                 # Sprites, backgrounds, icons
└── *.sks & audio files             # Scene files and background tracks
```

## 📥 Getting started
1. Clone the repository and open the Xcode project:
   ```bash
   git clone https://github.com/jdawud/FrogGame.git
   cd FrogGame
   open "Froggy Hopper.xcodeproj"
   ```
2. Select the **Froggy Hopper** target and run it on the iOS Simulator or a connected device.

> The repository does not include a compiled build or app store metadata—launching the project in Xcode is the recommended way to explore the game.

## 🤝 Contributing
Contributions are welcome! Feel free to open an issue or submit a pull request if you spot a bug or want to add a new feature.

## 📜 License
Released under the [MIT License](LICENSE).
