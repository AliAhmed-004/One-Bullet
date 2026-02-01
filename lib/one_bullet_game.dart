import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/arena_boundary.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/components/mobile_joystick.dart';
import 'package:one_bullet/components/player.dart';
import 'package:one_bullet/components/player_death_effect.dart';
import 'package:one_bullet/services/score_service.dart';

/// The main game class for One Bullet.
///
/// Uses HasKeyboardHandlerComponents to enable keyboard input for components.
/// Uses TapCallbacks to handle tap-to-fire mechanic.
/// Uses HasCollisionDetection for bullet-player collision.
class OneBulletGame extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, TapCallbacks, HasCollisionDetection {
  OneBulletGame({super.children});

  /// Overlay ID for the start screen.
  static const String startScreenOverlayId = 'startScreen';

  /// Overlay ID for the game over screen.
  static const String gameOverOverlayId = 'gameOver';

  /// Overlay ID for the game HUD.
  static const String gameHudOverlayId = 'gameHud';

  /// Overlay ID for the pause menu.
  static const String pauseOverlayId = 'pause';

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

  /// Whether the player is dead.
  bool _isGameOver = false;

  /// Whether the game has started (player has dismissed start screen).
  bool _hasStarted = false;

  /// Whether the game is currently paused by the user.
  bool _isPaused = false;

  /// Whether the latest game resulted in a new high score.
  bool isNewHighScore = false;

  /// Tracks the survival time (notifier for UI updates).
  final ValueNotifier<Duration> survivalTime = ValueNotifier(Duration.zero);

  /// Accumulated time in seconds for the timer.
  double _elapsedSeconds = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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
      survivalTime.value = Duration(milliseconds: (_elapsedSeconds * 1000).toInt());
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Don't fire if game not started, game over, already fired, or tapping in joystick zone
    if (!_hasStarted || _isGameOver || player == null || player!.hasFired) return;

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

    // Create and add the bullet
    bullet = Bullet(
      position: spawnPosition,
      direction: aimDirection,
    );
    world.add(bullet!);

    // Mark player as having fired
    player!.markAsFired();
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

    // Delay showing game over to let fragments animate
    Future.delayed(const Duration(milliseconds: 800), () {
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

    // Remove all overlays
    overlays.remove(pauseOverlayId);
    overlays.remove(gameHudOverlayId);

    // Remove game components except arena boundary
    world.removeAll(
      world.children.where((c) => c is! ArenaBoundary),
    );
    camera.viewport.removeAll(
      camera.viewport.children.whereType<MobileJoystick>(),
    );

    // Reset references
    player = null;
    joystick = null;
    bullet = null;

    // Initialize fresh game components (paused)
    _initializeGame();

    // Show start screen
    overlays.add(startScreenOverlayId);
    // Engine is already paused, no need to pause again
  }

  /// Restarts the game.
  void restart() {
    // Hide game over overlay
    overlays.remove(gameOverOverlayId);

    // Remove game components except arena boundary
    world.removeAll(
      world.children.where((c) => c is! ArenaBoundary),
    );
    camera.viewport.removeAll(
      camera.viewport.children.whereType<MobileJoystick>(),
    );

    // Reset references
    player = null;
    joystick = null;
    bullet = null;

    // Initialize fresh game components
    _initializeGame();

    // Show HUD, mark as started, and resume
    overlays.add(gameHudOverlayId);
    _hasStarted = true;
    resumeEngine();
  }
}

