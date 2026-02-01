import 'dart:collection';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';

/// The bullet that bounces off walls forever.
/// Only one bullet exists in the game - fired once by the player.
class Bullet extends CircleComponent with CollisionCallbacks {
  Bullet({
    required Vector2 position,
    required Vector2 direction,
    this.speed = 400.0,
    this.color = Colors.orange,
    this.trailLength = 12,
  }) : _velocity = direction.normalized() * speed,
       super(
         position: position,
         radius: 8,
         anchor: Anchor.center,
         paint: Paint()..color = color,
       );

  /// Speed of the bullet in pixels per second.
  final double speed;

  /// Color of the bullet.
  final Color color;

  /// Number of trail segments to keep.
  final int trailLength;

  /// Current velocity of the bullet.
  final Vector2 _velocity;

  /// Stores recent positions for the trail effect.
  final Queue<Vector2> _trailPositions = Queue<Vector2>();

  /// Getter for velocity (useful for debugging or effects).
  Vector2 get velocity => _velocity;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for collision detection
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Draw the trail first (behind the bullet)
    _renderTrail(canvas);

    // Draw the main circle (fill)
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Add a glowing effect / border
    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(radius, radius), radius, glowPaint);
  }

  /// Renders the fading trail behind the bullet.
  void _renderTrail(Canvas canvas) {
    if (_trailPositions.isEmpty) return;

    final trailList = _trailPositions.toList();
    final count = trailList.length;

    for (int i = 0; i < count; i++) {
      // Calculate opacity: older positions are more transparent
      final opacity = (i + 1) / count * 0.6; // Max 0.6 opacity for trail
      final trailRadius = radius * (0.3 + 0.5 * (i + 1) / count); // Shrinking trail

      final trailPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Convert world position to local coordinates
      final worldPos = trailList[i];
      final localX = worldPos.x - position.x + radius;
      final localY = worldPos.y - position.y + radius;

      canvas.drawCircle(Offset(localX, localY), trailRadius, trailPaint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Store current position for trail (before moving)
    _trailPositions.addLast(position.clone());

    // Keep only the last N positions
    while (_trailPositions.length > trailLength) {
      _trailPositions.removeFirst();
    }

    // Move the bullet
    position += _velocity * dt;

    // Check for wall collisions and bounce
    _handleWallBounce();
  }

  /// Handles bouncing off the arena boundaries.
  void _handleWallBounce() {
    final game = findGame();
    if (game is! OneBulletGame || game.arenaBoundary == null) return;

    // Get arena bounds with bullet radius inset
    final bounds = game.arenaBoundary!.getBoundsWithInset(radius);

    // Bounce off left/right walls
    if (position.x <= bounds.left) {
      position.x = bounds.left;
      _velocity.x = _velocity.x.abs(); // Ensure moving right
    } else if (position.x >= bounds.right) {
      position.x = bounds.right;
      _velocity.x = -_velocity.x.abs(); // Ensure moving left
    }

    // Bounce off top/bottom walls
    if (position.y <= bounds.top) {
      position.y = bounds.top;
      _velocity.y = _velocity.y.abs(); // Ensure moving down
    } else if (position.y >= bounds.bottom) {
      position.y = bounds.bottom;
      _velocity.y = -_velocity.y.abs(); // Ensure moving up
    }
  }
}
