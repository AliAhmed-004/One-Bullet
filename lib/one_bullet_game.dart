import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_bullet/components/arena_boundary.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/components/deflector.dart';
import 'package:one_bullet/components/game_background.dart';
import 'package:one_bullet/components/mobile_joystick.dart';
import 'package:one_bullet/components/player.dart';
import 'package:one_bullet/components/wave_manager.dart';
import 'package:one_bullet/debug/frame_logger.dart';
import 'package:one_bullet/game/death_sequence.dart';
import 'package:one_bullet/game/deflector_spawner.dart';
import 'package:one_bullet/game/input_controller.dart';
import 'package:one_bullet/game/run_state.dart';
import 'package:one_bullet/game_config.dart';
import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/sound_service.dart';

export 'package:one_bullet/game/input_controller.dart' show ControlMode;

/// The main game class for One Bullet.
///
/// Thin coordinator: it owns the Flame components and the screen flow
/// (overlays, pause, restart) and delegates the rest:
///  - [InputController] / BotPilot: keyboard, joystick and bot input
///  - [RunState]: per-run flags, survival clock and HUD notifiers
///  - [DeflectorSpawner]: deflector spawning and cap
///  - [DeathSequence]: death animation, score, ads, game over screen
///  - [WaveManager]: wave timing and bullet speed
class OneBulletGame extends FlameGame
    with KeyboardEvents, DragCallbacks, TapCallbacks, HasCollisionDetection {
  OneBulletGame({super.children});

  /// Overlay ID for the start screen.
  static const String startScreenOverlayId = 'startScreen';

  /// Overlay ID for the game over screen.
  static const String gameOverOverlayId = 'gameOver';

  /// Overlay ID for the game HUD.
  static const String gameHudOverlayId = 'gameHud';

  /// Overlay ID for the pause menu.
  static const String pauseOverlayId = 'pause';

  /// Overlay ID for settings
  static const String settingsOverlayId = 'settings';

  /// Overlay ID to show the full achievements list.
  static const String achievementsOverlayId = 'achievements';

  /// Overlay ID to show the leaderboards.
  static const String leaderboardsOverlayId = 'leaderboards';

  /// Height reserved for the HUD at the top of the screen.
  static const double hudHeight = 125.0;

  /// Reference to the arena boundary.
  ArenaBoundary? arenaBoundary;

  /// Reference to the game background.
  GameBackground? gameBackground;

  /// Reference to the player for easy access.
  Player? player;

  /// Reference to the mobile joystick for touch controls.
  MobileJoystick? joystick;

  /// Reference to the bullet (only one exists).
  Bullet? bullet;

  /// Reference to the wave manager.
  WaveManager? waveManager;

  /// Optional recording mode to keep captures clean and deterministic.
  bool isRecordingMode = false;

  /// Per-run state and HUD notifiers.
  final RunState run = RunState();

  /// Keyboard / joystick / bot input.
  final InputController input = InputController();

  late final DeflectorSpawner _deflectors = DeflectorSpawner(world: world);
  late final DeathSequence _death = DeathSequence(this);

  // --- UI-facing accessors (used by the Flutter overlays) -----------------

  /// Survival time (notifier for UI updates).
  ValueNotifier<Duration> get survivalTime => run.survivalTime;

  /// Current wave number and flash state for the HUD.
  ValueNotifier<({int waveNumber, bool isFlashing})> get waveState =>
      run.waveState;

  /// Whether the latest game resulted in a new high score.
  bool get isNewHighScore => run.isNewHighScore;

  /// Whether a continue is available.
  bool get canContinue => !run.hasUsedContinue && AdService.isRewardedAdReady;

  // --- Lifecycle -----------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Note: AchievementService is initialized in main.dart before Play Games

    await SoundService.init();
    FrameLogger.context = () =>
        'wave=${run.waveState.value.waveNumber} deflectors=${_deflectors.activeCount}';

    // Arena boundary persists across games and must be fully loaded before
    // other components use it.
    arenaBoundary = ArenaBoundary(topPadding: hudHeight);
    await world.add(arenaBoundary!);

    // Dynamic background renders behind all game elements.
    gameBackground = GameBackground();
    await world.add(gameBackground!);

    // Show start screen and pause the game.
    overlays.add(startScreenOverlayId);
    pauseEngine();

    // Pre-load the game components (but paused).
    _initializeGame();
  }

  @override
  void onRemove() {
    run.dispose();
    _death.cancel();
    super.onRemove();
  }

  /// Creates the per-run components without starting gameplay.
  void _initializeGame() {
    run.reset();
    input.reset();

    // Reset background state for a fresh run while keeping it mounted.
    gameBackground?.setWave(1);

    // Player starts at the arena center, offset down for the HUD.
    player = Player(position: Vector2(0, hudHeight / 2));
    world.add(player!);

    // Joystick renders in screen space, not world space.
    joystick = MobileJoystick(
      isInActivationZone: _isInArena,
      onMovementStart: _onPlayerMovementStart,
      onInputChanged: input.setJoystick,
    );
    camera.viewport.add(joystick!);

    waveManager = WaveManager(
      onWaveChange: _onWaveChange,
      onSpeedChange: (speed) => bullet?.setSpeed(speed),
      onSpawnDeflectors: _onSpawnDeflectors,
    );
    add(waveManager!);
  }

  /// Removes every per-run component, keeping the arena and background.
  void _clearRun() {
    SoundService.stopAll();

    world.removeAll(
      world.children.where((c) => c is! ArenaBoundary && c is! GameBackground),
    );
    camera.viewport.removeAll(
      camera.viewport.children.whereType<MobileJoystick>(),
    );
    waveManager?.removeFromParent();

    player = null;
    joystick = null;
    bullet = null;
    waveManager = null;
    _deflectors.clear();
  }

  /// Called when player taps "Start" on the start screen.
  void startGame() {
    run.hasStarted = true;
    // Profiling builds play themselves so long runs can be measured.
    if (FrameLogger.enabled && !input.isBot) toggleBotMode();
    overlays.remove(startScreenOverlayId);
    overlays.add(gameHudOverlayId);
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _updateBulletVisuals();

    final p = player;
    if (!run.isActive || p == null) return;

    final b = bullet;
    final bulletLive = b != null && p.hasFired;
    final movement = input.movement(
      dt,
      playerPosition: p.position,
      bulletPosition: bulletLive ? b.position : null,
      bulletVelocity: bulletLive ? b.velocity : null,
    );
    p.move(movement, dt);

    // Moving fires the bullet (bot waits for its fire delay).
    if (!p.hasFired && movement.length2 > 0 && input.canAutoFire(dt)) {
      _fireBullet();
    }

    // The survival clock starts with the bullet.
    if (p.hasFired) run.tick(dt);
  }

  // --- Input ---------------------------------------------------------------

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    input.updateKeyboard(keysPressed);

    if (event is KeyDownEvent && kDebugMode) {
      if (event.logicalKey == LogicalKeyboardKey.keyB) {
        toggleBotMode();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        isRecordingMode = !isRecordingMode;
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _tryManualFire();
  }

  /// Called when player starts moving via joystick.
  void _onPlayerMovementStart() => _tryManualFire();

  /// Fires on a player tap / first joystick move, if allowed.
  void _tryManualFire() {
    if (input.isBot) return;

    // Don't fire if game not started, game over, or already fired.
    if (!run.hasStarted || run.isGameOver) return;
    if (player == null || player!.hasFired) return;

    _fireBullet();
  }

  /// Debug-only toggle for bot control mode.
  void toggleBotMode() {
    input.toggleBot(playerHasFired: player?.hasFired ?? true);
  }

  /// Returns true if a screen-space point is inside the arena.
  bool _isInArena(Vector2 canvasPosition) {
    if (arenaBoundary == null) return false;

    // The world origin is centered on the screen.
    final worldPosition = Offset(
      canvasPosition.x - (size.x / 2),
      canvasPosition.y - (size.y / 2),
    );

    return arenaBoundary!.bounds.contains(worldPosition);
  }

  // --- Bullet & waves ---------------------------------------------------------

  void _fireBullet() {
    final p = player;
    final indicator = p?.aimIndicator;
    if (p == null || p.hasFired || indicator == null) return;

    bullet = Bullet(
      position: indicator.absolutePosition.clone(),
      direction: p.aimDirection.normalized(),
      speed: WaveManager.waves[0].startSpeed,
    );
    world.add(bullet!);

    p.markAsFired();
    waveManager?.start();
  }

  void _onWaveChange(int newWave, bool isWarning) {
    run.waveState.value = (waveNumber: newWave, isFlashing: isWarning);
  }

  /// Keeps bullet VFX synced to the global heat model and player distance.
  void _updateBulletVisuals() {
    final b = bullet;
    if (b == null) return;

    b.setEnvironmentHeat(GameConfig.heat);
    b.updateThreat(run.hasStarted && !run.isGameOver ? player?.position : null);
  }

  void _onSpawnDeflectors(int count) {
    final arena = arenaBoundary;
    if (arena == null) return;

    _deflectors.spawn(count, arena.bounds);
  }

  /// Removes a deflector from tracking (called when destroyed).
  void removeDeflector(Deflector deflector) => _deflectors.remove(deflector);

  // --- Death -----------------------------------------------------------------

  /// Called when the player is hit by the bullet.
  Future<void> onPlayerDeath() async {
    if (run.isGameOver) return;
    final p = player;
    if (p == null) return;

    // Mark game over but DON'T pause - let the death animation play.
    run.isGameOver = true;
    _death.begin(p);
  }

  // --- Screen flow -------------------------------------------------------------

  /// Pauses the game (from HUD pause button).
  void pauseGame() {
    if (run.isPaused || run.isGameOver) return;

    run.isPaused = true;
    pauseEngine();
    SoundService.pauseAll();
    overlays.add(pauseOverlayId);
  }

  /// Resumes the game (from pause menu).
  void resumeGame() {
    if (!run.isPaused) return;

    run.isPaused = false;
    SoundService.resumeAll();
    overlays.remove(pauseOverlayId);
    resumeEngine();
  }

  /// Returns to the main menu (from pause menu).
  void returnToMenu() {
    _death.cancel();
    AdService.resetDeathCount();

    overlays
      ..remove(pauseOverlayId)
      ..remove(gameHudOverlayId)
      ..remove(settingsOverlayId)
      ..remove(gameOverOverlayId);

    _clearRun();
    _initializeGame(); // engine is already paused

    overlays.add(startScreenOverlayId);
  }

  /// Restarts the game.
  void restart() {
    _death.cancel();
    overlays.remove(gameOverOverlayId);

    _clearRun();
    _initializeGame();

    overlays.add(gameHudOverlayId);
    run.hasStarted = true;
    resumeEngine();
  }

  /// Continues the game after watching a rewarded ad.
  /// Player respawns at center, bullet continues, timer preserved.
  void continueGame() {
    if (run.hasUsedContinue) return; // Only one continue per run

    run.hasUsedContinue = true;
    run.isGameOver = false;

    overlays.remove(gameOverOverlayId);

    // Respawn without an aim indicator since the bullet is already in play.
    player = Player(
      position: Vector2(0, hudHeight / 2),
      skipAimIndicator: true,
    );
    world.add(player!);

    overlays.add(gameHudOverlayId);

    run.isPaused = false;
    resumeEngine();
  }

  /// Opens the settings overlay from the pause menu.
  void openSettings() {
    overlays.remove(pauseOverlayId);
    overlays.add(settingsOverlayId);
    pauseEngine();
    run.isPaused = true;
  }

  /// Closes the settings overlay and returns to the appropriate previous screen.
  void closeSettings() {
    overlays.remove(settingsOverlayId);
    if (run.isPaused) {
      overlays.add(pauseOverlayId);
    } else {
      overlays.add(startScreenOverlayId);
    }
  }
}
