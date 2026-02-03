# One Bullet

**A survival game about avoiding your own mistake.**

Fire a bullet. This bullet will **NEVER DESPAWN**. Dodge it, and see how long you can survive.

---

## 🎮 Gameplay

### Core Mechanics
1. **Fire once** — Tap the screen (or anywhere outside the joystick zone) to fire your bullet in the aimed direction
2. **Ricochet chaos** — The bullet bounces off arena walls forever, with slight angular deviations to prevent predictable patterns
3. **Survive** — Dodge your own bullet for as long as possible
4. **Death** — One hit and you're done

### Controls
- **Mobile (Touch)**:
  - Drag anywhere in the bottom quarter of the screen to activate the **virtual joystick**
  - Tap anywhere else to **fire** (before bullet is launched)
- **Desktop (Keyboard)**:
  - `W/A/S/D` or `Arrow Keys` — Move the player
  - Tap/Click to fire

### Wave System
The game features a progressive wave system that increases difficulty over time:

| Wave | Duration | Bullet Speed | Deflectors |
|------|----------|--------------|------------|
| 1    | 15s      | 350 → 400    | None       |
| 2    | 18s      | 400 → 450    | Every 5s   |
| 3    | 20s      | 450 → 500    | Every 8s   |
| 4    | 22s      | 500 → 550    | Every 5s   |
| 5    | 25s      | 550 → 650    | Every 5s   |
| 6    | ∞        | 650 → 720    | Every 3s   |

### Deflectors
Starting from Wave 2, wooden **deflectors** spawn randomly in the arena:
- They **bounce** the bullet in new directions when hit
- They **block** player movement
- They **break apart** after being hit by the bullet

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) + [Flame](https://flame-engine.org/) game engine
- **Local Storage**: [Hive](https://pub.dev/packages/hive) for high score persistence
- **Platforms**: Android, iOS, Linux, macOS, Windows, Web

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point, overlay setup
├── one_bullet_game.dart       # Main game class, state management
├── components/
│   ├── player.dart            # Player circle with keyboard/joystick input
│   ├── bullet.dart            # Bouncing bullet with trail effect
│   ├── deflector.dart         # Wooden obstacles that break on impact
│   ├── arena_boundary.dart    # Game arena walls
│   ├── aim_indicator.dart     # Pre-fire aiming UI
│   ├── mobile_joystick.dart   # Touch-based movement controls
│   ├── wave_manager.dart      # Wave progression & speed scaling
│   ├── wave_indicator.dart    # Wave UI component
│   └── player_death_effect.dart # Death animation fragments
├── overlays/
│   ├── start_screen_overlay.dart
│   ├── game_hud_overlay.dart
│   ├── pause_overlay.dart
│   ├── game_over_overlay.dart
│   └── wave_indicator_widget.dart
└── services/
    └── score_service.dart     # High score storage with Hive
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Dart SDK

### Installation
```bash
# Clone the repository
git clone <repo-url>
cd one_bullet

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📝 Features

- ✅ Single bullet that never despawns
- ✅ Deterministic bullet physics with slight launch imperfection
- ✅ Progressive wave system with speed ramping
- ✅ Destructible deflector obstacles
- ✅ Virtual joystick for mobile controls
- ✅ Keyboard support for desktop
- ✅ High score persistence
- ✅ Pause/Resume functionality
- ✅ Death animation with particle fragments
- ✅ Cross-platform support

---

## � Privacy Policy

**One Bullet** is committed to protecting your privacy.

### Data Collection
- **No personal data is collected** — We do not collect names, emails, or any personally identifiable information
- **No account required** — The game can be played without signing up or logging in
- **No analytics tracking** — We do not track your gameplay behavior or device information

### Local Storage
- **High scores** are stored locally on your device using Hive
- This data never leaves your device and is not transmitted to any server
- You can clear this data by uninstalling the app or clearing app data

### Third-Party Services
- Currently, **no third-party services** are integrated
- Future updates may include ads (Google AdMob) for users aged 12+, which will be disclosed in an updated privacy policy

### Children's Privacy
- This game is suitable for ages **12 and up**
- We do not knowingly collect any data from children

### Contact
For any privacy-related questions, please open an issue in this repository.

---

## �📜 License

This project is private and not published to pub.dev.