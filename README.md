# Froggy Hopper 🐸

![Gameplay Screenshot](screenshot.jpg) *<!-- Add actual screenshot file later -->*

A modern iOS arcade game built with SpriteKit featuring a hungry frog collecting bugs while avoiding obstacles. Published open-source to demonstrate Swift game development best practices.

## 🎮 Features
- **Character Control**: Tap-based movement system with smooth animations
- **Dynamic Environment**: Procedurally generated obstacles (logs, rocks) and collectibles (flies, spiders)
- **Progression System**: 10 levels with increasing difficulty and unique background music per level
- **Score Tracking**: Real-time scoring system with win/lose conditions
- **Time Challenge**: 2-minute countdown timer with visual feedback
- **Audio Management**: Background music and sound effects handling via dedicated `SoundManager`
- **Adaptive UI**: Responsive layout supporting all iOS device sizes

## 🛠️ Architecture
**Tech Stack**: Swift 5, SpriteKit, GameplayKit

### Key Components:
1. **GameViewController (Entry Point)**
   - Manages SKView presentation
   - Configures scene scaling and debug settings
   - Handles device orientation

2. **GameScene (Core Logic)**
   - Manages game state (playing/over)
   - Handles touch input and physics collisions
   - Controls spawn systems for:
     - Collectible food items 🪰
     - Environmental obstacles 🪵
   - Implements level progression system

3. **SoundManager (Audio Service)**
   - Background music playlist management
   - Sound effect triggering system
   - Audio session configuration

## 📥 Installation
```bash
git clone https://github.com/jdawud/FrogGame.git
open Froggy\ Hopper.xcodeproj
```

## 🏆 Scoring System
| Action                | Points |
|-----------------------|--------|
| Collect Fly           | +10    |
| Avoid Spider          | +5     |
| Complete Level        | +25    |
| Hit Obstacle          | -15    |

**Win Condition**: Reach 100+ points before timer expires

## 🤝 Contributing
We welcome contributions! Please follow our:
- [Code Style Guide](CODESTYLE.md)
- [Issue Reporting Guidelines](CONTRIBUTING.md)

🔒 **Prohibited**:
- Breaking changes to core gameplay mechanics
- Introduction of non-SpriteKit dependencies

## 📜 License
[MIT Licensed](LICENSE) - Free for educational and commercial use
