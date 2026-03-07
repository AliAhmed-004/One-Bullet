# Copilot & AI Agent Instructions for One Bullet Game

## Project Overview
Cross-platform 2D survival game (Flutter + Flame). Player fires a single bullet that bounces forever; survive as long as possible.

## Architecture

### Core Files
- `lib/one_bullet_game.dart` - Main game class, state management, overlay routing, deflector spawning
- `lib/components/wave_manager.dart` - Wave progression config (`WaveConfig`), speed ramping, deflector spawn timing
- `lib/components/bullet.dart` - Bounce physics, trail rendering, speed adjustments via `setSpeed()`
- `lib/components/player.dart` - Movement (keyboard + joystick), aim indicator, collision detection

### Component Pattern
All game entities extend Flame `Component`. Key callbacks:
```dart
@override Future<void> onLoad() async { /* init hitboxes, cache paints */ }
@override void onMount() { _gameRef = findGame() as OneBulletGame; } // cache once
@override void update(double dt) { /* frame-rate independent logic */ }
@override void render(Canvas canvas) { /* use cached Paint/Path only */ }
```

### State Flow
1. `OneBulletGame` manages overlays via string IDs (`startScreenOverlayId`, `gameOverOverlayId`, etc.)
2. Game state: `_hasStarted`, `_isGameOver`, `_isPaused` flags control update logic
3. Bullet fires → `WaveManager.start()` → callbacks: `onWaveChange`, `onSpeedChange`, `onSpawnDeflectors`
4. Player death → `onPlayerDeath()` → shows death effect → delayed overlay transition

### Services (all in `lib/services/`)
- `SoundService` - Static methods, throttled SFX playback with `_maxActivePlayers` cap
- `AchievementService` - Play Games integration, time-based achievements
- `AdService` - Rewarded ads for "continue" feature
- `ScoreService` - Hive-based local high score persistence

## Performance Rules (Critical)
Read `docs/flame_performance_audit.md` for full context. Key rules:

1. **Cache Paint/Path in `onLoad`**, never create in `render()`:
```dart
late final Paint _bodyPaint;
@override Future<void> onLoad() async {
  _bodyPaint = Paint()..color = Colors.brown;
}
```

2. **Avoid Vector2 temporaries** in hot paths:
```dart
// BAD: position += _velocity * dt;
// GOOD:
position.x += _velocity.x * dt;
position.y += _velocity.y * dt;
```

3. **Deflector cap**: `_maxActiveDeflectors = 16` prevents collision system overload
4. **SFX throttling**: Use `minIntervalMs` parameter in `_playSfx()` for frequent sounds

## Conventions
- **No global singletons** - access game via `findGame()` cached in `onMount()`
- **All timing uses `dt`** - never use wall clock for gameplay logic
- **Overlays** are Flutter widgets in `lib/overlays/`, registered in `main.dart`
- **Achievements** defined as constants in `lib/services/achievement_service.dart`

## Developer Workflow
```bash
flutter run                    # dev mode
flutter build apk --release    # Android release
flutter build ios --release    # iOS release
```
No automated tests - manual playtesting is primary.

## Adding New Features

**New obstacle type:**
1. Create component in `lib/components/` extending `PositionComponent with CollisionCallbacks`
2. Add hitbox in `onLoad()`, cache paints
3. Spawn from `OneBulletGame._onSpawnDeflectors()` or new callback in `WaveManager`

**New wave mechanic:**
1. Modify `WaveConfig` in `wave_manager.dart`
2. Add callback in `WaveManager` constructor, wire in `OneBulletGame._initializeGame()`

## Key Dependencies
- `flame: ^1.34.0` - Game engine
- `flame_audio: ^2.11.13` - Sound via `FlameAudio.play()`
- `hive_flutter` - Local storage for scores
- `games_services` - Play Games achievements/leaderboards
- `vibration` - Haptic feedback (check `Vibration.hasVibrator()` first)
