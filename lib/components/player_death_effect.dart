import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A fragment particle that flies outward when the player dies.
/// Multiple of these are spawned to create a "shatter" effect.
class PlayerFragment extends PositionComponent {
  PlayerFragment({
    required Vector2 position,
    required this.velocity,
    required this.color,
    required this.fragmentSize,
    this.rotationSpeed = 5.0,
    this.lifetime = 1.0,
    this.fadeOut = true,
  }) : _remainingLife = lifetime,
       super(
         position: position,
         size: Vector2.all(fragmentSize),
         anchor: Anchor.center,
       );

  /// Velocity of the fragment.
  final Vector2 velocity;

  /// Color of the fragment.
  final Color color;

  /// Size of this fragment.
  final double fragmentSize;

  /// Rotation speed in radians per second.
  final double rotationSpeed;

  /// Total lifetime in seconds.
  final double lifetime;

  /// Whether to fade out over time.
  final bool fadeOut;

  /// Remaining life of the fragment.
  double _remainingLife;

  /// Current opacity (1.0 = fully visible).
  double _opacity = 1.0;

  /// Gravity effect (fragments fall slightly).
  static const double gravity = 200.0;

  /// Friction to slow down fragments.
  static const double friction = 0.98;

  @override
  void update(double dt) {
    super.update(dt);

    // Update remaining life
    _remainingLife -= dt;

    // Remove when lifetime expires
    if (_remainingLife <= 0) {
      removeFromParent();
      return;
    }

    // Update opacity for fade out
    if (fadeOut) {
      _opacity = (_remainingLife / lifetime).clamp(0.0, 1.0);
    }

    // Apply gravity
    velocity.y += gravity * dt;

    // Apply friction
    velocity.scale(friction);

    // Move fragment
    position += velocity * dt;

    // Rotate fragment
    angle += rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = color.withValues(alpha: _opacity)
      ..style = PaintingStyle.fill;

    // Draw fragment as a small irregular polygon (triangle-ish)
    final path = Path();
    final halfSize = fragmentSize / 2;

    // Create a slightly irregular shape
    path.moveTo(halfSize * 0.8, 0);
    path.lineTo(halfSize * 1.5, halfSize * 0.7);
    path.lineTo(halfSize * 1.2, halfSize * 1.5);
    path.lineTo(halfSize * 0.3, halfSize * 1.3);
    path.lineTo(0, halfSize * 0.5);
    path.close();

    canvas.drawPath(path, paint);

    // Add a slight border for visibility
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: _opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }
}

/// Spawns player death fragments at the given position.
class PlayerDeathEffect {
  /// Creates and returns a list of fragment components.
  static List<PlayerFragment> createFragments({
    required Vector2 position,
    required Color color,
    int fragmentCount = 12,
    double baseSpeed = 250.0,
    double fragmentSize = 8.0,
  }) {
    final random = Random();
    final fragments = <PlayerFragment>[];

    for (int i = 0; i < fragmentCount; i++) {
      // Random angle for each fragment
      final angle = (i / fragmentCount) * 2 * pi + random.nextDouble() * 0.5;

      // Random speed variation
      final speed = baseSpeed * (0.5 + random.nextDouble());

      // Calculate velocity from angle and speed
      final velocity = Vector2(
        cos(angle) * speed,
        sin(angle) * speed,
      );

      // Random size variation
      final size = fragmentSize * (0.6 + random.nextDouble() * 0.8);

      // Random rotation speed
      final rotationSpeed = (random.nextDouble() - 0.5) * 10;

      // Slight position offset from center
      final offset = Vector2(
        (random.nextDouble() - 0.5) * 10,
        (random.nextDouble() - 0.5) * 10,
      );

      fragments.add(PlayerFragment(
        position: position + offset,
        velocity: velocity,
        color: color,
        fragmentSize: size,
        rotationSpeed: rotationSpeed,
        lifetime: 0.8 + random.nextDouble() * 0.4, // 0.8 to 1.2 seconds
      ));
    }

    return fragments;
  }
}
