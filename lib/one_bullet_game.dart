import 'dart:async';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/arena_boundary.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/components/deflector.dart';
import 'package:one_bullet/components/mobile_joystick.dart';
import 'package:one_bullet/components/player.dart';
import 'package:one_bullet/components/player_death_effect.dart';
import 'package:one_bullet/components/wave_manager.dart';
import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/services/sound_service.dart';
import 'package:one_bullet/services/achievement_service.dart';

/// The main game class for One Bullet.
///
/// Uses HasKeyboardHandlerComponents to enable keyboard input for components.
/// Uses TapCallbacks to handle tap-to-fire mechanic.
/// Uses HasCollisionDetection for bullet-player collision.
class OneBulletGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        TapCallbacks,
        HasCollisionDetection {
  OneBulletGame({super.children});

  /// Overlay ID for the start screen.
  static const String startScreenOverlayId = 'startScreen';

  /// Overlay ID for achievement unlock announcements.
  static const String achievementUnlockedOverlayId = 'achievementUnlocked';

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

  /// Height reserved for the HUD at the top of the screen.
  static const double hudHeight = 125.0;

  /// Reference to the arena boundary.
  ArenaBoundary? arenaBoundary;

  /// Reference to the player for easy access.
  Player? player;

  /// Reference to the mobile joystick for touch controls.
  MobileJoystick? joystick;

  /// Reference to the bullet (only one exists).
  Bullet? bullet;

  /// Reference to the wave manager.
  WaveManager? waveManager;

  /// Timer for delayed game over screen (cancellable).
  Timer? _gameOverTimer;

  /// List of active deflectors in the arena.
  final List<Deflector> _deflectors = [];

  /// Hard cap to prevent collision-system overload in long runs.
  static const int _maxActiveDeflectors = 16;

  /// Random number generator for deflector placement.
  final math.Random _rng = math.Random();

  /// Whether the player is dead.
  bool _isGameOver = false;

  /// Whether the game has started (player has dismissed start screen).
  bool _hasStarted = false;

  /// Whether the game is currently paused by the user.
  bool _isPaused = false;

  /// Whether the player has used their "continue" for this run.
  bool _hasUsedContinue = false;

  /// Whether the latest game resulted in a new high score.
  bool isNewHighScore = false;

  /// Whether a continue is available.
  bool get canContinue => !_hasUsedContinue && AdService.isRewardedAdReady;

  /// Tracks the survival time (notifier for UI updates).
  final ValueNotifier<Duration> survivalTime = ValueNotifier(Duration.zero);

  /// Tracks the current wave number and flash state for the HUD.
  final ValueNotifier<({int waveNumber, bool isFlashing})> waveState =
      ValueNotifier((waveNumber: 1, isFlashing: false));

  /// Accumulated time in seconds for the timer.
  double _elapsedSeconds = 0;
  double _uiUpdateAccumulator = 0;

  /// List of currently unlocked achievement IDs (cached for quick access).
  List<Achievement> lastUnlockedAchievements = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Note: AchievementService is initialized in main.dart before Play Games

    // Load all sound effects
    await SoundService.init();

    // Create the arena boundary (persists across games)
    // Must be fully loaded before other components use it
    arenaBoundary = ArenaBoundary(topPadding: hudHeight);
    await world.add(arenaBoundary!);

    // Show start screen and pause the game
    overlays.add(startScreenOverlayId);
    pauseEngine();

    // Pre-load the game components (but paused)
    _initializeGame();
  }

  /// Initializes game components without starting gameplay.
  void _initializeGame() {
    _isGameOver = false;
    _hasStarted = false;
    _isPaused = false;
    _hasUsedContinue = false;
    isNewHighScore = false;
    _elapsedSeconds = 0;
    survivalTime.value = Duration.zero;

    // Create and add the player at the center of the arena
    // Offset slightly down to account for HUD space
    final playerStartY = hudHeight / 2;
    player = Player(position: Vector2(0, playerStartY));
    world.add(player!);

    // Add the mobile joystick (renders in screen space, not world space)
    joystick = MobileJoystick(
      player: player!,
      isInActivationZone: _isInArena,
      onMovementStart: _onPlayerMovementStart,
    );
    camera.viewport.add(joystick!);

    // Create wave manager
    waveManager = WaveManager(
      onWaveChange: _onWaveChange,
      onSpeedChange: _onSpeedChange,
      onSpawnDeflectors: _onSpawnDeflectors,
    );
    add(waveManager!);
  }

  /// Called when player taps "Start" on the start screen.
  void startGame() {
    _hasStarted = true;
    overlays.remove(startScreenOverlayId);
    overlays.add(gameHudOverlayId); // Show HUD
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_hasStarted && !_isGameOver && !_isPaused && player?.hasFired == true) {
      _elapsedSeconds += dt;
      _uiUpdateAccumulator += dt;

      // Update UI only every 100ms
      if (_uiUpdateAccumulator >= 0.1) {
        survivalTime.value = Duration(
          milliseconds: (_elapsedSeconds * 1000).toInt(),
        );
        _uiUpdateAccumulator = 0;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Don't fire if game not started, game over, or already fired.
    if (!_hasStarted || _isGameOver || player == null || player!.hasFired) {
      return;
    }

    // Fire the bullet!
    _fireBullet();
  }

  /// Called when player starts moving via joystick.
  void _onPlayerMovementStart() {
    if (!_hasStarted || _isGameOver || player == null || player!.hasFired) {
      return;
    }

    _fireBullet();
  }

  /// Returns true if a screen-space point is inside the arena.
  bool _isInArena(Vector2 canvasPosition) {
    if (arenaBoundary == null) return false;

    final worldPosition = Vector2(
      canvasPosition.x - (size.x / 2),
      canvasPosition.y - (size.y / 2),
    );

    return arenaBoundary!.bounds.contains(
      Offset(worldPosition.x, worldPosition.y),
    );
  }

  /// Fires the bullet in the current aim direction.
  void _fireBullet() {
    if (player == null || player!.hasFired) return;

    // Get the aim direction from the player's aim indicator
    final aimDirection = player!.aimDirection;

    // Calculate bullet spawn position (at the edge of the player + offset)
    final spawnOffset = aimDirection * (player!.radius + 15);
    final spawnPosition = player!.position + spawnOffset;

    // Create and add the bullet with initial wave speed
    bullet = Bullet(
      position: spawnPosition,
      direction: aimDirection,
      speed: WaveManager.waves[0].startSpeed,
    );
    world.add(bullet!);

    // Mark player as having fired
    player!.markAsFired();

    // Start the wave system
    waveManager?.start();
  }

  /// Called when the wave number changes.
  void _onWaveChange(int newWave, bool isWarning) {
    // Update the wave state for HUD display
    waveState.value = (waveNumber: newWave, isFlashing: isWarning);
  }

  /// Called when the bullet speed should change.
  void _onSpeedChange(double newSpeed) {
    bullet?.setSpeed(newSpeed);
  }

  /// Called when deflectors should spawn at the start of a wave.
  void _onSpawnDeflectors(int count) {
    if (arenaBoundary == null) return;

    // Clean up stale references before deciding spawn budget.
    _deflectors.removeWhere(
      (deflector) => deflector.isRemoving || !deflector.isMounted,
    );

    final availableSlots = _maxActiveDeflectors - _deflectors.length;
    if (availableSlots <= 0) return;

    final spawnCount = math.min(count, availableSlots);

    final bounds = arenaBoundary!.bounds;
    // Margin from arena edges to ensure deflectors don't touch walls
    const margin = 60.0;

    for (int i = 0; i < spawnCount; i++) {
      // Generate random position and angle
      final position = Deflector.randomPositionInArena(bounds, _rng, margin);
      final angle = Deflector.randomAngle(_rng);

      // Create and add the deflector
      final deflector = Deflector(position: position, angle: angle);

      _deflectors.add(deflector);
      world.add(deflector);
    }
  }

  /// Removes a deflector from tracking (called when destroyed).
  void removeDeflector(Deflector deflector) {
    _deflectors.remove(deflector);
  }

  /// Called when the player is hit by the bullet.
  Future<void> onPlayerDeath() async {
    if (_isGameOver) return;
    if (player == null) return;

    /// 🔥 Freeze game immediately
    _isGameOver = true;
    pauseEngine();
    SoundService.stopAll();

    final playerPosition = player!.position.clone();
    const playerColor = Colors.blue;

    /// Remove player from world instantly
    player!.removeFromParent();

    final secondsSurvived = survivalTime.value.inSeconds;

    /// Check rewards + score in parallel
    final achievementFuture = AchievementService.instance
        .checkAndUnlockForSurvivalTime(secondsSurvived);

    final highScoreFuture = Future.value(
      ScoreService.checkAndSaveHighScore(survivalTime.value),
    );

    final results = await Future.wait([achievementFuture, highScoreFuture]);

    lastUnlockedAchievements = results[0] as List<Achievement>;
    isNewHighScore = results[1] as bool;

    /// Spawn death effects
    final fragments = PlayerDeathEffect.createFragments(
      position: playerPosition,
      color: playerColor,
      fragmentCount: 14,
      baseSpeed: 300.0,
    );

    world.addAll(fragments);

    /// Play SFX
    if (isNewHighScore) {
      SoundService.playHighScore();
    } else {
      SoundService.playPlayerDeath();
    }

    /// Ad + Reward Flow
    final showedInterstitial = AdService.onPlayerDeath(
      secondsSurvived,
      onInterstitialDismissed: () {
        Future.delayed(
          const Duration(milliseconds: 400),
          _showPostDeathOverlayFlow,
        );
      },
    );

    /// If no ad was shown, continue directly
    if (!showedInterstitial) {
      _gameOverTimer?.cancel();
      _gameOverTimer = Timer(
        const Duration(milliseconds: 300),
        _showPostDeathOverlayFlow,
      );
    }
  }

  void _showPostDeathOverlayFlow() {
    if (!_isGameOver) return;

    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    pauseEngine();
    SoundService.stopAll();

    overlays.remove(gameHudOverlayId);

    if (lastUnlockedAchievements.isNotEmpty) {
      overlays.add(achievementUnlockedOverlayId);
    } else {
      overlays.add(gameOverOverlayId);
    }
  }

  /// Pauses the game (from HUD pause button).
  void pauseGame() {
    if (_isPaused || _isGameOver) return;

    _isPaused = true;
    pauseEngine();
    SoundService.pauseAll();
    overlays.add(pauseOverlayId);
  }

  /// Resumes the game (from pause menu).
  void resumeGame() {
    if (!_isPaused) return;

    _isPaused = false;
    SoundService.resumeAll();
    overlays.remove(pauseOverlayId);
    resumeEngine();
  }

  /// Returns to the main menu (from pause menu).
  void returnToMenu() {
    _isPaused = false;

    // Cancel any pending game over timer
    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    AdService.resetDeathCount();

    // Remove all overlays
    overlays.remove(pauseOverlayId);
    overlays.remove(gameHudOverlayId);
    overlays.remove(settingsOverlayId);
    overlays.remove(achievementUnlockedOverlayId);
    overlays.remove(gameOverOverlayId);

    // Stop all active sound effects before teardown
    SoundService.stopAll();

    // Remove game components except arena boundary
    world.removeAll(world.children.where((c) => c is! ArenaBoundary));
    camera.viewport.removeAll(
      camera.viewport.children.whereType<MobileJoystick>(),
    );

    // Remove wave manager
    waveManager?.removeFromParent();

    // Reset references
    player = null;
    joystick = null;
    bullet = null;
    waveManager = null;
    _deflectors.clear();

    // Initialize fresh game components (paused)
    _initializeGame();

    // Show start screen
    overlays.add(startScreenOverlayId);
    // Engine is already paused, no need to pause again
  }

  @override
  void onRemove() {
    // Dispose ValueNotifiers to prevent memory leaks
    survivalTime.dispose();
    waveState.dispose();

    // Cancel any pending timers
    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    super.onRemove();
  }

  /// Called by the achievement overlay once its animation has completed.
  void onAchievementOverlayComplete() {
    overlays.remove(achievementUnlockedOverlayId);

    if (_isGameOver) {
      overlays.add(gameOverOverlayId);
    }
  }

  /// Restarts the game.
  void restart() {
    // Cancel any pending game over timer
    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    // Hide game over overlay
    overlays.remove(achievementUnlockedOverlayId);
    overlays.remove(gameOverOverlayId);

    // Stop all active sound effects before teardown
    SoundService.stopAll();

    // Remove game components except arena boundary
    world.removeAll(world.children.where((c) => c is! ArenaBoundary));
    camera.viewport.removeAll(
      camera.viewport.children.whereType<MobileJoystick>(),
    );

    // Remove wave manager and reset references
    waveManager?.removeFromParent();

    // Reset references
    player = null;
    joystick = null;
    bullet = null;
    waveManager = null;
    _deflectors.clear();

    // Reset wave state to initial values
    waveState.value = (waveNumber: 1, isFlashing: false);

    // Initialize fresh game components
    _initializeGame();

    // Show HUD, mark as started, and resume
    overlays.add(gameHudOverlayId);
    _hasStarted = true;
    resumeEngine();
  }

  /// Continues the game after watching a rewarded ad.
  /// Player respawns at center, bullet continues, timer preserved.
  void continueGame() {
    if (_hasUsedContinue) {
      return; // Only one continue per run
    }

    _hasUsedContinue = true;
    _isGameOver = false;

    // Hide game over overlay
    overlays.remove(achievementUnlockedOverlayId);
    overlays.remove(gameOverOverlayId);

    // Respawn the player at the center of the arena (skip aim indicator since bullet is in play)
    final playerStartY = hudHeight / 2;
    player = Player(position: Vector2(0, playerStartY), skipAimIndicator: true);
    world.add(player!);

    // Update joystick reference to new player
    joystick?.updatePlayer(player!);

    // Show HUD
    overlays.add(gameHudOverlayId);

    // Resume engine (make sure it's running)
    _isPaused = false;
    resumeEngine();
  }

  /// Opens the settings overlay from the pause menu.
  void openSettings() {
    // Remove pause menu and show settings
    overlays.remove(pauseOverlayId);
    overlays.add(settingsOverlayId);
    pauseEngine();
    _isPaused = true;
  }

  /// Closes the settings overlay and returns to the appropriate previous screen.
  void closeSettings() {
    overlays.remove(settingsOverlayId);
    if (_isPaused) {
      overlays.add(pauseOverlayId);
    } else {
      overlays.add(startScreenOverlayId);
    }
  }
}
