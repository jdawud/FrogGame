# Froggy Feed! Architecture Overview

**SpriteKit arcade game** — iOS 16+ / Swift 5 / UIKit lifecycle

Frog hops to eat bugs before time runs out. 10 levels, Game Center integration, haptic feedback.

---

## Scene Flow

```
GameViewController → WelcomeScene → GameScene → Game Over (inline)
```

- `WelcomeScene`: Animated title, Start/Leaderboard buttons
- `GameScene`: 120s timer, reach 100 pts to advance, physics-based collision

---

## Key Files

| File | Purpose |
|------|---------|
| `GameScene.swift` | Core gameplay (~540 lines): physics, scoring, timer, level progression |
| `GameScene+Spawning.swift` | Extension for food/obstacle spawning logic |
| `WelcomeScene.swift` | Title screen with animations |
| `SoundManager.swift` | Singleton for AVAudioPlayer (music + SFX) |
| `GameCenterManager.swift` | Auth, leaderboards, achievements |
| `SceneDelegate.swift` | Single source of truth for pause/resume (posts custom notifications) |

---

## GameConfig

```swift
enum GameConfig {
    static let levelDuration: TimeInterval = 120.0
    static let pointsToWin: Int = 100
    static let maxHopDistance: CGFloat = 80.0
    static let totalLevels: Int = 10
    static let flySpiderPoints: Int = 2
    static let antPoints: Int = 1
}
```

---

## Physics

| Category | Bitmask |
|----------|---------|
| `frog` | 0b1 |
| `food` | 0b10 |
| `obstacle` | 0b100 |

Frog raycasts toward obstacles to shorten hop distance.

---

## Testing

Swift Testing framework (`@Test` macro). 5 test files covering scenes, managers, and view controller.

---

## Notes

- **Pause handling**: `SceneDelegate` is single source of truth — posts `.gameShouldPause`/`.gameShouldResume` notifications that `GameScene` observes
- **Game over**: Handled inline in `GameScene` (no separate scene)
- **Scoring**: `totalScore` accumulates across levels

---
