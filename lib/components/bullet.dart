import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The bullet that bounces off walls forever.
/// Only one bullet exists in the game - fired once by the player.
class Bullet extends CircleComponent {
  Bullet({
    required Vector2 position,
    required Vector2 direction,
    this.speed = 400.0,
    this.color = Colors.orange,
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

  /// Current velocity of the bullet.
  final Vector2 _velocity;

  /// Getter for velocity (useful for debugging or effects).
  Vector2 get velocity => _velocity;

  @override
  void render(Canvas canvas) {
    // Draw the main circle (fill)
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Add a glowing effect / border
    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(radius, radius), radius, glowPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the bullet
    position += _velocity * dt;

    // Check for wall collisions and bounce
    _handleWallBounce();
  }

  /// Handles bouncing off the screen boundaries.
  void _handleWallBounce() {
    final game = findGame();
    if (game == null) return;

    final gameSize = game.size;

    // Calculate bounds (world coordinates with camera at center)
    final minX = -gameSize.x / 2 + radius;
    final maxX = gameSize.x / 2 - radius;
    final minY = -gameSize.y / 2 + radius;
    final maxY = gameSize.y / 2 - radius;

    // Bounce off left/right walls
    if (position.x <= minX) {
      position.x = minX;
      _velocity.x = _velocity.x.abs(); // Ensure moving right
    } else if (position.x >= maxX) {
      position.x = maxX;
      _velocity.x = -_velocity.x.abs(); // Ensure moving left
    }

    // Bounce off top/bottom walls
    if (position.y <= minY) {
      position.y = minY;
      _velocity.y = _velocity.y.abs(); // Ensure moving down
    } else if (position.y >= maxY) {
      position.y = maxY;
      _velocity.y = -_velocity.y.abs(); // Ensure moving up
    }
  }
}
