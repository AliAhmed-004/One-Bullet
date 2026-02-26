# Copilot & AI Agent Instructions for One Bullet Game

Welcome to the One Bullet codebase! This guide is for AI coding agents (Copilot, Cursor, Claude, etc.) to maximize productivity and maintain project conventions.

## Project Overview
- **Type:** Cross-platform 2D survival game built with Flutter & Flame
- **Core Loop:** Player fires a single bullet that bounces forever; survive as long as possible
- **Key Files:**
  - `lib/one_bullet_game.dart`: Main game logic, state, and loop
  - `lib/components/`: Player, bullet, deflectors, wave manager, UI overlays
  - `lib/services/`: Sound, settings, and other utilities
  - `assets/`: Images and audio for game elements

## Architecture & Patterns
- **Component System:** Uses Flame's ECS-like `Component` model. Each entity (player, bullet, deflector) is a `Component` subclass.
- **Game State:** Managed in `OneBulletGame` (see `lib/one_bullet_game.dart`). Avoid global state; use game instance references.
- **Wave Progression:** Controlled by `WaveManager` (`lib/components/wave_manager.dart`). Bullet speed and deflector spawn rates scale per wave.
- **Cross-Platform Input:**
  - Mobile: Virtual joystick (bottom screen), tap to fire
  - Desktop: WASD/Arrow keys, mouse click to fire
  - See overlays and input handling in `lib/overlays/` and `lib/components/player.dart`
- **Performance:**
  - Minimize `Vector2` temporaries in hot paths (see `docs/flame_performance_audit.md`)
  - Cache `Paint`/`Path` objects in `onLoad` for render-heavy components
  - Cap active deflectors to avoid unbounded collision checks
- **Audio:** Use pooled SFX playback for short sounds; avoid per-play `AudioPlayer` allocations

## Developer Workflows
- **Build:** `flutter run` for dev, `flutter build <platform>` for release
- **Assets:** Add to `assets/` and update `pubspec.yaml` under `assets:`
- **Testing:** Manual playtesting is primary; no automated tests yet
- **Performance Audit:** See `docs/flame_performance_audit.md` for optimization strategies

## Project-Specific Conventions
- **No global singletons** (except for Flame/Game root)
- **Prefer composition over inheritance** for new game features
- **All gameplay logic should be frame-rate independent** (use `dt` in updates)
- **UI overlays** (start, game over, etc.) live in `lib/overlays/`
- **High scores** are stored locally via Hive; no network or analytics

## Integration & Dependencies
- **Flutter** (main UI/game framework)
- **Flame** (game engine)
- **Hive** (local storage)
- **Vibration** (haptic feedback)
- **Audio**: Use `audioplayers` or `AudioPool` for SFX

## Examples
- **Adding a new obstacle:**
  - Create a new `Component` in `lib/components/`
  - Register and spawn via `WaveManager` or `OneBulletGame`
- **Optimizing a render loop:**
  - Move `Paint`/`Path` creation to `onLoad`
  - Avoid per-frame allocations in `render()`

## References
- [README.md](../README.md): Game design, features, and controls
- [docs/flame_performance_audit.md](../docs/flame_performance_audit.md): Performance best practices

---
**When in doubt, check `lib/one_bullet_game.dart` and `docs/flame_performance_audit.md` for canonical patterns.**
