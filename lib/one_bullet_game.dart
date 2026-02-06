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
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/services/sound_service.dart';

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

  /// Overlay ID for the game over screen.
  static const String gameOverOverlayId = 'gameOver';

  /// Overlay ID for the game HUD.
  static const String gameHudOverlayId = 'gameHud';

  /// Overlay ID for the pause menu.
  static const String pauseOverlayId = 'pause';

  /// Overlay ID for settings
  static const String settingsOverlayId = 'settings';

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
  /// TODO: Re-enable when ads are implemented after Play Store publication.
  /// TODO: Remember to configure ads for ages 12+.
  bool get canContinue => false;

  /// Tracks the survival time (notifier for UI updates).
  final ValueNotifier<Duration> survivalTime = ValueNotifier(Duration.zero);

  /// Tracks the current wave number and flash state for the HUD.
  final ValueNotifier<({int waveNumber, bool isFlashing})> waveState =
      ValueNotifier((waveNumber: 1, isFlashing: false));

  /// Accumulated time in seconds for the timer.
  double _elapsedSeconds = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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
    joystick = MobileJoystick(player: player!);
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

    // Update survival timer only after the bullet has been fired
    if (_hasStarted && !_isGameOver && !_isPaused && player?.hasFired == true) {
      _elapsedSeconds += dt;
      survivalTime.value = Duration(
        milliseconds: (_elapsedSeconds * 1000).toInt(),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Don't fire if game not started, game over, already fired, or tapping in joystick zone
    if (!_hasStarted || _isGameOver || player == null || player!.hasFired) {
      return;
    }

    // Check if tap is in the joystick activation zone (bottom quarter)
    // If so, don't fire - let the joystick handle it
    if (event.canvasPosition.y >= size.y * 0.75) return;

    // Fire the bullet!
    _fireBullet();
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

    final bounds = arenaBoundary!.bounds;
    // Margin from arena edges to ensure deflectors don't touch walls
    const margin = 60.0;

    for (int i = 0; i < count; i++) {
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
  void onPlayerDeath() {
    if (_isGameOver) return; // Prevent multiple triggers

    _isGameOver = true;

    // Check and save high score
    isNewHighScore = ScoreService.checkAndSaveHighScore(survivalTime.value);

    // Store player position and color before removing
    final playerPosition = player!.position.clone();
    const playerColor = Colors.blue;

    // Remove the player immediately
    player!.removeFromParent();

    // Spawn death fragments
    final fragments = PlayerDeathEffect.createFragments(
      position: playerPosition,
      color: playerColor,
      fragmentCount: 14,
      baseSpeed: 300.0,
    );

    // Add all fragments to the world
    world.addAll(fragments);

    // TODO: Re-enable ad showing after Play Store publication
    // AdService.onPlayerDeath(survivalTime.value.inSeconds);

    // Play appropriate sound effect based on whether it's a new high score or not
    if (isNewHighScore) {
      SoundService.playHighScore();
    } else {
      SoundService.playPlayerDeath();
    }

    // Delay showing game over to let fragments animate (cancellable timer)
    _gameOverTimer?.cancel();
    _gameOverTimer = Timer(const Duration(milliseconds: 800), () {
      // Pause the game
      pauseEngine();

      // Hide HUD and show game over overlay
      overlays.remove(gameHudOverlayId);
      overlays.add(gameOverOverlayId);
    });
  }

  /// Pauses the game (from HUD pause button).
  void pauseGame() {
    if (_isPaused || _isGameOver) return;

    _isPaused = true;
    pauseEngine();
    overlays.add(pauseOverlayId);
  }

  /// Resumes the game (from pause menu).
  void resumeGame() {
    if (!_isPaused) return;

    _isPaused = false;
    overlays.remove(pauseOverlayId);
    resumeEngine();
  }

  /// Returns to the main menu (from pause menu).
  void returnToMenu() {
    _isPaused = false;

    // Cancel any pending game over timer
    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    // TODO: Re-enable ad reset after Play Store publication
    // AdService.resetDeathCount();

    // Remove all overlays
    overlays.remove(pauseOverlayId);
    overlays.remove(gameHudOverlayId);

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

  /// Restarts the game.
  void restart() {
    // Cancel any pending game over timer
    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    // Hide game over overlay
    overlays.remove(gameOverOverlayId);

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
    debugPrint(
      'OneBulletGame: continueGame() called, _hasUsedContinue=$_hasUsedContinue',
    );

    if (_hasUsedContinue) {
      debugPrint('OneBulletGame: Already used continue, returning');
      return; // Only one continue per run
    }

    _hasUsedContinue = true;
    _isGameOver = false;

    // Hide game over overlay
    overlays.remove(gameOverOverlayId);
    debugPrint('OneBulletGame: Removed game over overlay');

    // Respawn the player at the center of the arena (skip aim indicator since bullet is in play)
    final playerStartY = hudHeight / 2;
    player = Player(position: Vector2(0, playerStartY), skipAimIndicator: true);
    world.add(player!);
    debugPrint('OneBulletGame: Added new player');

    // Update joystick reference to new player
    joystick?.updatePlayer(player!);

    // Show HUD
    overlays.add(gameHudOverlayId);
    debugPrint('OneBulletGame: Added HUD overlay');

    // Resume engine (make sure it's running)
    _isPaused = false;
    resumeEngine();
    debugPrint('OneBulletGame: Engine resumed, paused=$paused');
  }

  /// Opens the settings overlay from the pause menu.
  void openSettings() {
    // Remove pause menu and show settings
    overlays.remove(pauseOverlayId);
    overlays.add(settingsOverlayId);
    pauseEngine();
    _isPaused = true;
  }

  /// Closes the settings overlay and returns to the pause menu.
  void closeSettings() {
    // Remove settings and show pause menu
    overlays.remove(settingsOverlayId);
    overlays.add(pauseOverlayId);
    pauseEngine();
    _isPaused = true;
  }
}
