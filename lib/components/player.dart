import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_bullet/components/aim_indicator.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/one_bullet_game.dart';

/// The Player component - a circle that the user controls.
class Player extends CircleComponent
    with KeyboardHandler, CollisionCallbacks {
  Player({required super.position, Color? color})
    : super(
        anchor: Anchor.center,
        radius: 20,
        paint: Paint()
          ..color = color ?? Colors.blue
          ..style = PaintingStyle.fill,
      );

  /// Movement speed in pixels per second.
  static const double speed = 300.0;

  /// The aim indicator that rotates around the player.
  late final AimIndicator aimIndicator;

  /// Whether the bullet has been fired.
  bool _hasFired = false;

  /// Getter to check if bullet has been fired.
  bool get hasFired => _hasFired;

  /// Mark that the bullet has been fired.
  void markAsFired() {
    _hasFired = true;
    aimIndicator.removeFromParent(); // Remove aim indicator after firing
  }

  /// Returns the current aim direction from the indicator.
  Vector2 get aimDirection => aimIndicator.aimDirection;

  /// Current movement direction (normalized or zero).
  /// This can be set by keyboard input OR joystick input.
  Vector2 _movementDirection = Vector2.zero();

  /// Getter for movement direction (useful for external joystick control).
  Vector2 get movementDirection => _movementDirection;

  /// Set movement direction externally (e.g., from a joystick).
  /// The vector should be normalized or have magnitude <= 1.
  void setMovementDirection(Vector2 direction) {
    _movementDirection = direction;
  }

  // Track which keys are currently pressed
  final Set<LogicalKeyboardKey> _keysPressed = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for collision detection
    add(CircleHitbox());

    // Add the aim indicator as a child (rotates around player)
    aimIndicator = AimIndicator(orbitRadius: 45);
    add(aimIndicator);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Check if collided with bullet
    if (other is Bullet) {
      // Notify the game that player died
      final game = findGame();
      if (game is OneBulletGame) {
        game.onPlayerDeath();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Calculate movement based on direction and speed
    if (_movementDirection != Vector2.zero()) {
      position += _movementDirection * speed * dt;
    }

    // Clamp player position to stay within game bounds
    _clampToGameBounds();
  }

  /// Keeps the player within the arena bounds.
  void _clampToGameBounds() {
    final game = findGame();
    if (game is! OneBulletGame || game.arenaBoundary == null) return;

    // Get arena bounds with player radius inset
    final bounds = game.arenaBoundary!.getBoundsWithInset(radius);

    position.x = position.x.clamp(bounds.left, bounds.right);
    position.y = position.y.clamp(bounds.top, bounds.bottom);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);

    // Update movement direction based on pressed keys
    _updateMovementFromKeyboard();

    return false; // Allow other components to also handle the event
  }

  /// Updates the movement direction based on currently pressed keys.
  void _updateMovementFromKeyboard() {
    // Reset direction
    _movementDirection = Vector2.zero();

    // Check for horizontal movement (A/D or Left/Right arrows)
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _movementDirection.x -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _movementDirection.x += 1;
    }

    // Check for vertical movement (W/S or Up/Down arrows)
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _movementDirection.y -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _movementDirection.y += 1;
    }

    // Normalize diagonal movement so it's not faster
    if (_movementDirection.length > 0) {
      _movementDirection.normalize();
    }
  }
}

