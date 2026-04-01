import 'dart:async';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum ControlMode { player, bot }

/// The main game class for One Bullet.
///
/// Uses KeyboardEvents to capture movement/debug key input at game level.
/// Uses TapCallbacks to handle tap-to-fire mechanic.
/// Uses HasCollisionDetection for bullet-player collision.
class OneBulletGame extends FlameGame
    with
    KeyboardEvents,
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

  /// Overlay ID to show the full achievements list.
  static const String achievementsOverlayId = 'achievements';

  /// Overlay ID to show the leaderboards.
  static const String leaderboardsOverlayId = 'leaderboards';

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

  /// Active control source for player movement.
  ControlMode controlMode = ControlMode.player;

  /// Optional recording mode to keep captures clean and deterministic.
  bool isRecordingMode = false;

  /// Bot tuning parameters.
  double dangerRadius = 90;
  double predictionTime = 0.8;
  double panicRandomness = 0.3;
  double mistakeChance = 0.05;
  double idleSpeed = 0.6;
  double botFireDelaySeconds = 2.5;

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

  /// Player input collected from keyboard.
  final Vector2 _keyboardInput = Vector2.zero();

  /// Player input collected from mobile joystick.
  final Vector2 _joystickInput = Vector2.zero();

  /// Reused vector for merged player input.
  final Vector2 _movementInput = Vector2.zero();

  /// Reused vector for bot output.
  final Vector2 _botInput = Vector2.zero();

  /// Reused vector for predicted bullet position.
  final Vector2 _botFutureBulletPos = Vector2.zero();

  /// Reused vector for panic direction.
  final Vector2 _botPanicDirection = Vector2.zero();

  /// Reused vector for randomness added to panic movement.
  final Vector2 _botRandomness = Vector2.zero();

  /// Reused vector for delayed bot decisions.
  final Vector2 _botDelayedInput = Vector2.zero();

  double _botTime = 0;
  double _botReactionDelayRemaining = 0;
  double _botFireDelayRemaining = 0;

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
    _keyboardInput.setZero();
    _joystickInput.setZero();
    _movementInput.setZero();
    _botInput.setZero();
    _botDelayedInput.setZero();
    _botReactionDelayRemaining = 0;
    _botFireDelayRemaining = botFireDelaySeconds;
    _botTime = 0;

    // Create and add the player at the center of the arena
    // Offset slightly down to account for HUD space
    final playerStartY = hudHeight / 2;
    player = Player(position: Vector2(0, playerStartY));
    world.add(player!);

    // Add the mobile joystick (renders in screen space, not world space)
    joystick = MobileJoystick(
      isInActivationZone: _isInArena,
      onMovementStart: _onPlayerMovementStart,
      onInputChanged: _setJoystickInput,
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

    if (_hasStarted && !_isGameOver && !_isPaused && player != null) {
      final input = getMovementInput(dt);
      player!.move(input, dt);

      // Preserve "move to fire" behavior through the centralized input path.
      if (!player!.hasFired && input.length2 > 0 && _canAutoFire(dt)) {
        _fireBullet();
      }
    }

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
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _updateKeyboardInput(keysPressed);

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

    if (controlMode == ControlMode.bot) {
      return;
    }

    // Don't fire if game not started, game over, or already fired.
    if (!_hasStarted || _isGameOver || player == null || player!.hasFired) {
      return;
    }

    // Fire the bullet!
    _fireBullet();
  }

  /// Called when player starts moving via joystick.
  void _onPlayerMovementStart() {
    if (controlMode == ControlMode.bot) return;

    if (!_hasStarted || _isGameOver || player == null || player!.hasFired) {
      return;
    }

    _fireBullet();
  }

  /// Merges control sources into a single movement vector.
  Vector2 getMovementInput(double dt) {
    if (controlMode == ControlMode.bot) {
      return getBotInput(dt);
    }

    _movementInput
      ..setFrom(_keyboardInput)
      ..add(_joystickInput);

    if (_movementInput.length2 > 1) {
      _movementInput.normalize();
    }

    return _movementInput;
  }

  /// Returns bot-generated movement input for cinematic dodging.
  Vector2 getBotInput(double dt) {
    _botTime += dt;

    if (player == null) {
      _botInput.setZero();
      return _botInput;
    }

    if (_botReactionDelayRemaining > 0) {
      _botReactionDelayRemaining -= dt;
      _botInput.setFrom(_botDelayedInput);
      return _botInput;
    }

    final hasLiveBullet = bullet != null && player!.hasFired;
    if (!hasLiveBullet) {
      _setIdleBotInput();
      return _botInput;
    }

    _botFutureBulletPos
      ..setFrom(bullet!.position)
      ..addScaled(bullet!.velocity, predictionTime);

    final distanceToFuturePos = player!.position.distanceTo(_botFutureBulletPos);
    if (distanceToFuturePos > dangerRadius) {
      _setIdleBotInput();
      return _botInput;
    }

    _botPanicDirection
      ..setFrom(player!.position)
      ..sub(_botFutureBulletPos);

    if (_botPanicDirection.length2 < 0.0001) {
      _botPanicDirection
        ..setValues(_rng.nextDouble() * 2 - 1, _rng.nextDouble() * 2 - 1)
        ..normalize();
    }

    _botRandomness
      ..setValues(_rng.nextDouble() * 2 - 1, _rng.nextDouble() * 2 - 1)
      ..scale(panicRandomness);

    _botInput
      ..setFrom(_botPanicDirection)
      ..add(_botRandomness);

    if (_botInput.length2 > 0) {
      _botInput.normalize();
    }

    if (_rng.nextDouble() < mistakeChance) {
      _botInput.scale(-1);
    }

    // Optional reaction delay to avoid machine-perfect inputs.
    _botDelayedInput.setFrom(_botInput);
    _botReactionDelayRemaining = 0.03 + _rng.nextDouble() * 0.09;

    return _botInput;
  }

  /// Debug-only toggle for bot control mode.
  void toggleBotMode() {
    if (!kDebugMode) return;

    controlMode =
        (controlMode == ControlMode.player) ? ControlMode.bot : ControlMode.player;

    if (controlMode == ControlMode.bot && player?.hasFired == false) {
      _botFireDelayRemaining = botFireDelaySeconds;
    }
  }

  bool _canAutoFire(double dt) {
    if (controlMode != ControlMode.bot) {
      return true;
    }

    if (_botFireDelayRemaining <= 0) {
      return true;
    }

    _botFireDelayRemaining -= dt;
    return _botFireDelayRemaining <= 0;
  }

  void _setIdleBotInput() {
    _botInput.setValues(
      math.sin(_botTime * 0.9),
      math.cos(_botTime * 0.7 + 1.2),
    );

    if (_botInput.length2 > 0) {
      _botInput.normalize();
    }

    _botInput.scale(idleSpeed);
    _botDelayedInput.setFrom(_botInput);
    _botReactionDelayRemaining = 0;
  }

  void _setJoystickInput(Vector2 input) {
    _joystickInput.setFrom(input);
  }

  void _updateKeyboardInput(Set<LogicalKeyboardKey> keysPressed) {
    _keyboardInput.setZero();

    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _keyboardInput.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _keyboardInput.x += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _keyboardInput.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _keyboardInput.y += 1;
    }

    if (_keyboardInput.length2 > 0) {
      _keyboardInput.normalize();
    }
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

  /// Duration to wait for death animation before showing ad/overlay.
  static const Duration _deathAnimationDuration = Duration(milliseconds: 1200);

  /// Called when the player is hit by the bullet.
  Future<void> onPlayerDeath() async {
    if (_isGameOver) return;
    if (player == null) return;

    // Mark game over but DON'T pause - let death animation play
    _isGameOver = true;

    final playerPosition = player!.position.clone();
    const playerColor = Colors.blue;

    // Remove player from world instantly
    player!.removeFromParent();

    final secondsSurvived = survivalTime.value.inSeconds;

    // Check achievements (but don't unlock yet - we'll do that after game over shows)
    lastUnlockedAchievements = AchievementService.instance
        .getAchievementsForSurvivalTime(secondsSurvived);

    // Check high score (local save only; leaderboard sync happens later)
    isNewHighScore = ScoreService.checkAndSaveHighScoreLocally(
      survivalTime.value,
    );

    // Spawn death effect fragments
    final fragments = PlayerDeathEffect.createFragments(
      position: playerPosition,
      color: playerColor,
      fragmentCount: 14,
      baseSpeed: 300.0,
    );
    world.addAll(fragments);

    // Play death SFX
    if (isNewHighScore) {
      SoundService.playHighScore();
    } else {
      SoundService.playPlayerDeath();
    }

    // Wait for death animation to complete, then show ad/game over
    _gameOverTimer?.cancel();
    _gameOverTimer = Timer(_deathAnimationDuration, () {
      _onDeathAnimationComplete(secondsSurvived);
    });
  }

  /// Called after death animation completes. Shows ad if available, then game over.
  void _onDeathAnimationComplete(int secondsSurvived) {
    // Now pause the engine since animation is done
    pauseEngine();
    SoundService.stopAll();

    // Try to show interstitial ad
    final showedInterstitial = AdService.onPlayerDeath(
      secondsSurvived,
      onInterstitialDismissed: () {
        // Small delay after ad dismissal for smoother transition
        Future.delayed(
          const Duration(milliseconds: 200),
          _showGameOverAndUnlockAchievements,
        );
      },
    );

    // If no ad was shown, go directly to game over
    if (!showedInterstitial) {
      _showGameOverAndUnlockAchievements();
    }
  }

  /// Shows game over overlay and triggers Play Games achievement unlock.
  void _showGameOverAndUnlockAchievements() {
    if (!_isGameOver) return;

    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    // Ensure engine is paused and sounds stopped
    pauseEngine();
    SoundService.stopAll();

    // Hide HUD and show game over overlay
    overlays.remove(gameHudOverlayId);
    overlays.add(gameOverOverlayId);

    // Now unlock achievements and sync leaderboard (native popups will show over game over screen)
    if (lastUnlockedAchievements.isNotEmpty) {
      // Small delay to let game over overlay render first
      Future.delayed(const Duration(milliseconds: 300), () {
        AchievementService.instance.unlockAchievements(
          lastUnlockedAchievements,
        );
      });
    }

    // Save high score to leaderboard asynchronously (non-blocking)
    if (isNewHighScore) {
      ScoreService.saveScoreToGooglePlayGames(survivalTime.value);
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

  /// Restarts the game.
  void restart() {
    // Cancel any pending game over timer
    _gameOverTimer?.cancel();
    _gameOverTimer = null;

    // Hide game over overlay
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
    overlays.remove(gameOverOverlayId);

    // Respawn the player at the center of the arena (skip aim indicator since bullet is in play)
    final playerStartY = hudHeight / 2;
    player = Player(position: Vector2(0, playerStartY), skipAimIndicator: true);
    world.add(player!);

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
