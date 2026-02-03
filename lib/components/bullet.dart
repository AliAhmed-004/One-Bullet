import 'dart:math' as math;

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
  }) : _velocity = _applyLaunchImperfection(direction.normalized() * speed),
       _currentSpeed = speed,
       super(
         position: position,
         radius: 8,
         anchor: Anchor.center,
         paint: Paint()..color = color,
       );

  /// Applies a one-time small random angular offset at launch (±2-3 degrees).
  /// This is the ONLY source of randomness in the bullet's behavior.
  static Vector2 _applyLaunchImperfection(Vector2 velocity) {
    // Random number generator seeded once at launch
    final rng = math.Random();
    
    // Random offset between -3 and +3 degrees (in radians)
    final maxOffset = 3 * math.pi / 180; // 3 degrees in radians
    final offset = (rng.nextDouble() * 2 - 1) * maxOffset;
    
    // Rotate velocity by the offset
    final cosA = math.cos(offset);
    final sinA = math.sin(offset);
    
    return Vector2(
      velocity.x * cosA - velocity.y * sinA,
      velocity.x * sinA + velocity.y * cosA,
    );
  }

  /// Speed of the bullet in pixels per second (initial value).
  final double speed;

  /// Current speed of the bullet (can change with waves).
  double _currentSpeed;

  /// Color of the bullet.
  final Color color;

  /// Number of trail segments to keep.
  final int trailLength;

  /// Current velocity of the bullet.
  final Vector2 _velocity;

  /// Circular buffer for trail positions (more efficient than Queue).
  late final List<Vector2> _trailPositions;
  
  /// Current write index for circular buffer.
  int _trailIndex = 0;
  
  /// Number of valid positions in the trail buffer.
  int _trailCount = 0;

  /// Cached Paint for glow effect (avoid recreation each frame).
  late final Paint _glowPaint;
  
  /// Cached Paint for trail rendering (reused with color updates).
  late final Paint _trailPaint;
  
  /// Cached reference to the game (avoid findGame() each frame).
  OneBulletGame? _gameRef;

  /// Bounce counter for deterministic deviation calculation.
  int _bounceCount = 0;

  /// Perpendicular bias strength as a fraction of speed (~2-3% deviation).
  static const double _perpBiasStrength = 0.025;
  
  /// Epsilon threshold for axis-alignment breaking (~0.85 degrees).
  static const double _axisEpsilon = 0.015;

  /// Getter for velocity (useful for debugging or effects).
  Vector2 get velocity => _velocity;

  /// Getter for current speed.
  double get currentSpeed => _currentSpeed;

  /// Updates the bullet speed (called by WaveManager).
  /// Smoothly adjusts velocity magnitude while preserving direction.
  void setSpeed(double newSpeed) {
    if (newSpeed == _currentSpeed) return;
    
    _currentSpeed = newSpeed;
    
    // Preserve direction, update magnitude
    _velocity.normalize();
    _velocity.scale(_currentSpeed);
  }

  /// Reflects the bullet off a deflector with the given reflection vector.
  /// 1. Applies the reflection
  /// 2. Then applies perpendicular deviation
  void reflectOffDeflector(Vector2 reflectedVelocity) {
    // Set the new velocity direction from the reflection
    _velocity.setFrom(reflectedVelocity.normalized() * _currentSpeed);
    
    // Apply the standard perpendicular deviation
    _applyBounceDeviation();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for collision detection
    add(CircleHitbox());
    
    // Initialize circular buffer for trail positions
    _trailPositions = List.generate(trailLength, (_) => Vector2.zero());
    
    // Initialize cached paints
    _glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    _trailPaint = Paint()
      ..style = PaintingStyle.fill;
  }
  
  @override
  void onMount() {
    super.onMount();
    // Cache game reference to avoid findGame() calls each frame
    _gameRef = findGame() as OneBulletGame?;
  }

  @override
  void render(Canvas canvas) {
    // Draw the trail first (behind the bullet)
    _renderTrail(canvas);

    // Draw the main circle (fill)
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Add a glowing effect / border (using cached paint)
    canvas.drawCircle(Offset(radius, radius), radius, _glowPaint);
  }

  /// Renders the fading trail behind the bullet.
  void _renderTrail(Canvas canvas) {
    if (_trailCount == 0) return;

    for (int i = 0; i < _trailCount; i++) {
      // Calculate the actual index in circular buffer (oldest first)
      final bufferIndex = (_trailIndex - _trailCount + i + trailLength) % trailLength;
      
      // Calculate opacity: older positions are more transparent
      final opacity = (i + 1) / _trailCount * 0.6; // Max 0.6 opacity for trail
      final trailRadius = radius * (0.3 + 0.5 * (i + 1) / _trailCount); // Shrinking trail

      // Reuse cached paint, just update color
      _trailPaint.color = color.withValues(alpha: opacity);

      // Convert world position to local coordinates
      final worldPos = _trailPositions[bufferIndex];
      final localX = worldPos.x - position.x + radius;
      final localY = worldPos.y - position.y + radius;

      canvas.drawCircle(Offset(localX, localY), trailRadius, _trailPaint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Store current position in circular buffer (before moving)
    _trailPositions[_trailIndex].setFrom(position);
    _trailIndex = (_trailIndex + 1) % trailLength;
    if (_trailCount < trailLength) _trailCount++;

    // Move the bullet
    position += _velocity * dt;

    // Check for wall collisions and bounce
    _handleWallBounce();
  }

  /// Handles bouncing off the arena boundaries.
  void _handleWallBounce() {
    if (_gameRef == null || _gameRef!.arenaBoundary == null) return;

    // Get arena bounds with bullet radius inset
    final bounds = _gameRef!.arenaBoundary!.getBoundsWithInset(radius);

    bool bounced = false;

    // Bounce off left/right walls
    if (position.x <= bounds.left) {
      position.x = bounds.left;
      _velocity.x = _velocity.x.abs(); // Ensure moving right
      bounced = true;
    } else if (position.x >= bounds.right) {
      position.x = bounds.right;
      _velocity.x = -_velocity.x.abs(); // Ensure moving left
      bounced = true;
    }

    // Bounce off top/bottom walls
    if (position.y <= bounds.top) {
      position.y = bounds.top;
      _velocity.y = _velocity.y.abs(); // Ensure moving down
      bounced = true;
    } else if (position.y >= bounds.bottom) {
      position.y = bounds.bottom;
      _velocity.y = -_velocity.y.abs(); // Ensure moving up
      bounced = true;
    }

    // Apply subtle deviation on bounce
    if (bounced) {
      _applyBounceDeviation();
    }
  }

  /// Applies a subtle, deterministic deviation to the velocity after a bounce.
  /// Uses perpendicular vector bias based on bounce count for predictable deflections.
  void _applyBounceDeviation() {
    _bounceCount++;

    // Calculate perpendicular vector to current velocity
    final perp = Vector2(-_velocity.y, _velocity.x)..normalize();

    // Deterministic bias using sine wave with golden ratio multiplier
    // Creates non-repeating but predictable pattern
    final bias = math.sin(_bounceCount * 1.618) * _perpBiasStrength * _currentSpeed;

    // Apply perpendicular bias to velocity
    _velocity.add(perp * bias);

    // Normalize and reapply speed to maintain constant velocity
    _velocity.normalize();
    _velocity.scale(_currentSpeed);

    // Ensure velocity never aligns perfectly with axes
    _breakAxisAlignment();
  }

  /// Ensures the bullet velocity is never perfectly horizontal or vertical.
  /// Nudges the velocity slightly if either component is below epsilon threshold.
  void _breakAxisAlignment() {
    final vxAbs = _velocity.x.abs() / _currentSpeed;
    final vyAbs = _velocity.y.abs() / _currentSpeed;

    bool needsRenormalize = false;

    // If nearly horizontal, nudge vertical component
    if (vyAbs < _axisEpsilon) {
      // Nudge in direction based on bounce count for determinism
      final sign = (_bounceCount % 2 == 0) ? 1.0 : -1.0;
      _velocity.y = _axisEpsilon * _currentSpeed * sign;
      needsRenormalize = true;
    }

    // If nearly vertical, nudge horizontal component
    if (vxAbs < _axisEpsilon) {
      final sign = (_bounceCount % 2 == 0) ? 1.0 : -1.0;
      _velocity.x = _axisEpsilon * _currentSpeed * sign;
      needsRenormalize = true;
    }

    // Re-normalize to maintain constant speed
    if (needsRenormalize) {
      _velocity.normalize();
      _velocity.scale(_currentSpeed);
    }
  }
}
