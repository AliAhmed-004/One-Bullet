import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/components/player.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/sound_service.dart';

/// A wooden obstacle that deflects bullets and blocks player movement.
/// Spawns starting from wave 5 and breaks apart when hit by a bullet.
class Deflector extends PositionComponent with CollisionCallbacks {
  Deflector({
    required Vector2 position,
    required double angle,
    this.width = 80.0,
    this.height = 16.0,
  }) : super(
         position: position,
         size: Vector2(width, height),
         anchor: Anchor.center,
         angle: angle,
       );

  /// Width of the deflector.
  @override
  final double width;

  /// Height of the deflector.
  @override
  final double height;

  /// Wood-like brown color.
  static const Color woodColor = Color(0xFF8B4513); // Saddle brown
  static const Color woodDarkColor = Color(0xFF5D2E0C); // Darker brown
  static const Color woodLightColor = Color(0xFFA0522D); // Sienna

  /// Cached Paint objects for rendering (avoid recreation each frame).
  late final Paint _bodyPaint;
  late final Paint _grainPaint;
  late final Paint _highlightPaint;
  late final Paint _borderPaint;

  /// Whether this deflector has been destroyed.
  bool _isDestroyed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add a rectangular hitbox for collision detection
    add(RectangleHitbox());
    
    // Initialize cached paints (avoid creating in render loop)
    _bodyPaint = Paint()
      ..color = woodColor
      ..style = PaintingStyle.fill;
    
    _grainPaint = Paint()
      ..color = woodDarkColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    _highlightPaint = Paint()
      ..color = woodLightColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    _borderPaint = Paint()
      ..color = woodDarkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Main wood body (using cached paint)
    final bodyRect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(2));
    canvas.drawRRect(rrect, _bodyPaint);

    // Wood grain lines (using cached paint)
    for (int i = 1; i < 4; i++) {
      final y = height * i / 4;
      canvas.drawLine(Offset(3, y), Offset(width - 3, y), _grainPaint);
    }

    // Highlight on top edge (using cached paint)
    canvas.drawLine(const Offset(2, 2), Offset(width - 2, 2), _highlightPaint);

    // Border (using cached paint)
    canvas.drawRRect(rrect, _borderPaint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Handle bullet collision
    if (other is Bullet && !_isDestroyed) {
      _handleBulletCollision(other, intersectionPoints);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Handle player collision - push player away
    if (other is Player) {
      _handlePlayerCollision(other, intersectionPoints);
    }
  }

  /// Handles bullet hitting the deflector.
  /// 1. Reflects velocity normally based on surface normal
  /// 2. Then applies perpendicular deviation (handled by bullet)
  void _handleBulletCollision(Bullet bullet, Set<Vector2> intersectionPoints) {
    _isDestroyed = true;

    // play sound effect
    SoundService.playDeflectorBreak();

    // Calculate the surface normal of the deflector
    // The deflector's "up" direction in world space
    final surfaceNormal = Vector2(0, -1)..rotate(angle);

    // Get bullet velocity
    final velocity = bullet.velocity;

    // Check which side the bullet is coming from
    final dotProduct = velocity.dot(surfaceNormal);

    // If bullet is coming from the "back" side, flip the normal
    final normal = dotProduct > 0 ? -surfaceNormal : surfaceNormal;

    // Reflect velocity: v' = v - 2(v·n)n
    final reflection = velocity - (normal * (2 * velocity.dot(normal)));

    // Apply the reflection to the bullet
    bullet.reflectOffDeflector(reflection);

    // Spawn destruction fragments
    _spawnDestructionFragments();

    // Remove this deflector
    removeFromParent();
  }

  /// Handles player colliding with the deflector.
  /// Pushes the player out of the deflector.
  void _handlePlayerCollision(Player player, Set<Vector2> intersectionPoints) {
    if (intersectionPoints.isEmpty) return;

    // Calculate push direction (from deflector center to player)
    final pushDirection = (player.position - position).normalized();

    // Push player out slightly
    player.position.add(pushDirection * 2);
  }

  /// Spawns wood fragment particles when destroyed.
  void _spawnDestructionFragments() {
    final game = findGame();
    if (game is! OneBulletGame) return;

    final fragments = DeflectorDestructionEffect.createFragments(
      position: position,
      angle: angle,
      width: width,
      height: height,
    );

    game.world.addAll(fragments);
  }

  /// Generates a random position inside the arena bounds with margin.
  static Vector2 randomPositionInArena(
    Rect bounds,
    math.Random rng,
    double margin,
  ) {
    final minX = bounds.left + margin;
    final maxX = bounds.right - margin;
    final minY = bounds.top + margin;
    final maxY = bounds.bottom - margin;

    return Vector2(
      minX + rng.nextDouble() * (maxX - minX),
      minY + rng.nextDouble() * (maxY - minY),
    );
  }

  /// Generates a random angle in radians.
  static double randomAngle(math.Random rng) {
    return rng.nextDouble() * math.pi; // 0 to 180 degrees
  }
}

/// A fragment particle from a destroyed deflector.
class DeflectorFragment extends PositionComponent {
  DeflectorFragment({
    required Vector2 position,
    required this.velocity,
    required this.fragmentSize,
    this.rotationSpeed = 5.0,
    this.lifetime = 0.8,
  }) : _remainingLife = lifetime,
       super(
         position: position,
         size: Vector2.all(fragmentSize),
         anchor: Anchor.center,
       );

  /// Velocity of the fragment.
  final Vector2 velocity;

  /// Size of this fragment.
  final double fragmentSize;

  /// Rotation speed in radians per second.
  final double rotationSpeed;

  /// Total lifetime in seconds.
  final double lifetime;

  /// Remaining life of the fragment.
  double _remainingLife;

  /// Current opacity.
  double _opacity = 1.0;

  /// Gravity effect.
  static const double gravity = 250.0;

  /// Friction to slow down fragments.
  static const double friction = 0.97;
  
  /// Cached Paint for fill (reused with color updates).
  late final Paint _fillPaint;
  
  /// Cached Paint for border (reused with color updates).
  late final Paint _borderPaint;
  
  /// Cached Path for fragment shape (computed once).
  late final Path _fragmentPath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize cached paints
    _fillPaint = Paint()..style = PaintingStyle.fill;
    _borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Pre-compute the fragment path (shape doesn't change)
    final halfSize = fragmentSize / 2;
    _fragmentPath = Path()
      ..moveTo(halfSize * 0.2, halfSize * 0.1)
      ..lineTo(halfSize * 1.8, halfSize * 0.3)
      ..lineTo(halfSize * 1.6, halfSize * 1.7)
      ..lineTo(halfSize * 0.4, halfSize * 1.5)
      ..close();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _remainingLife -= dt;

    if (_remainingLife <= 0) {
      removeFromParent();
      return;
    }

    _opacity = (_remainingLife / lifetime).clamp(0.0, 1.0);

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

    // Update cached paint colors with current opacity
    _fillPaint.color = Deflector.woodColor.withValues(alpha: _opacity);
    _borderPaint.color = Deflector.woodDarkColor.withValues(alpha: _opacity * 0.7);

    // Draw using cached path and paints
    canvas.drawPath(_fragmentPath, _fillPaint);
    canvas.drawPath(_fragmentPath, _borderPaint);
  }
}

/// Creates destruction fragments for a deflector.
class DeflectorDestructionEffect {
  static List<DeflectorFragment> createFragments({
    required Vector2 position,
    required double angle,
    required double width,
    required double height,
    int fragmentCount = 10,
    double baseSpeed = 200.0,
  }) {
    final random = math.Random();
    final fragments = <DeflectorFragment>[];

    for (int i = 0; i < fragmentCount; i++) {
      // Random angle biased toward the deflector's orientation
      final fragmentAngle = angle + (random.nextDouble() - 0.5) * math.pi;

      // Random speed
      final speed = baseSpeed * (0.4 + random.nextDouble() * 0.8);

      // Calculate velocity
      final velocity = Vector2(
        math.cos(fragmentAngle) * speed,
        math.sin(fragmentAngle) * speed - 50, // Slight upward bias
      );

      // Random size
      final size = 4.0 + random.nextDouble() * 6.0;

      // Random rotation speed
      final rotationSpeed = (random.nextDouble() - 0.5) * 12;

      // Position offset along the deflector's length
      final offset = Vector2(
        (random.nextDouble() - 0.5) * width * 0.8,
        (random.nextDouble() - 0.5) * height,
      )..rotate(angle);

      fragments.add(
        DeflectorFragment(
          position: position + offset,
          velocity: velocity,
          fragmentSize: size,
          rotationSpeed: rotationSpeed,
          lifetime: 0.6 + random.nextDouble() * 0.4,
        ),
      );
    }

    return fragments;
  }
}
