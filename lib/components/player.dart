import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/aim_indicator.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/one_bullet_game.dart';

/// The Player component - a circle that the user controls.
class Player extends CircleComponent with CollisionCallbacks {
  Player({required super.position, Color? color, this.skipAimIndicator = false})
    : super(
        anchor: Anchor.center,
        radius: 20,
        paint: Paint()
          ..color = color ?? Colors.blue
          ..style = PaintingStyle.fill,
      );

  /// If true, don't create the aim indicator (used for respawning after continue).
  final bool skipAimIndicator;

  /// Movement speed in pixels per second (tuned for challenging gameplay).
  static const double speed = 260.0;

  /// The aim indicator that rotates around the player (null if skipped).
  AimIndicator? aimIndicator;

  /// Whether the bullet has been fired.
  bool _hasFired = false;

  /// Getter to check if bullet has been fired.
  bool get hasFired => _hasFired || skipAimIndicator;

  /// Mark that the bullet has been fired.
  void markAsFired() {
    _hasFired = true;
    // Only remove if it exists
    aimIndicator?.removeFromParent();
  }

  /// Returns the current aim direction from the indicator.
  Vector2 get aimDirection => aimIndicator?.aimDirection ?? Vector2(0, -1);
  
  /// Cached reference to the game (avoid findGame() each frame).
  OneBulletGame? _gameRef;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for collision detection
    add(CircleHitbox());

    // Add the aim indicator as a child (rotates around player)
    // Skip for respawned players (bullet already fired)
    if (!skipAimIndicator) {
      aimIndicator = AimIndicator(orbitRadius: 45);
      add(aimIndicator!);
    }
  }
  
  @override
  void onMount() {
    super.onMount();
    // Cache game reference to avoid findGame() calls each frame
    _gameRef = findGame() as OneBulletGame?;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Check if collided with bullet
    if (other is Bullet) {
      // Notify the game that player died (use cached reference)
      _gameRef?.onPlayerDeath();
    }
  }

  /// Moves the player using normalized (or zero) input from the game.
  void move(Vector2 input, double dt) {
    if (input.length2 > 0) {
      position.addScaled(input, speed * dt);
    }

    _clampToGameBounds();
  }

  /// Keeps the player within the arena bounds.
  void _clampToGameBounds() {
    if (_gameRef == null || _gameRef!.arenaBoundary == null) return;

    // Get arena bounds with player radius inset
    final bounds = _gameRef!.arenaBoundary!.getBoundsWithInset(radius);

    position.x = position.x.clamp(bounds.left, bounds.right);
    position.y = position.y.clamp(bounds.top, bounds.bottom);
  }
}
