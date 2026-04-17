import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/settings_service.dart';
import 'package:one_bullet/services/sound_service.dart';
import 'package:vibration/vibration.dart';

final math.Random _rng = math.Random(); // reuse, don’t recreate

class Bullet extends SpriteComponent with CollisionCallbacks {
  Bullet({
    required Vector2 position,
    required Vector2 direction,
    this.speed = 400.0,
  }) : _velocity = _applyLaunchImperfection(direction.normalized() * speed),
       _currentSpeed = speed,
       super(position: position, size: Vector2(20, 12), anchor: Anchor.center);

  final double speed;
  double _currentSpeed;
  final Vector2 _velocity;

  OneBulletGame? _gameRef;

  int _bounceCount = 0;

  static const double _perpBiasStrength = 0.025;
  static const double _axisEpsilon = 0.015;

  static bool? _canVibrate;

  final Vector2 _perpendicular = Vector2.zero();

  double _lastBounceEffectTime = -1;
  double _elapsedTime = 0;

  static const double _bounceEffectCooldown = 0.045;

  double _trailTimer = 0;

  Vector2 get velocity => _velocity;
  double get currentSpeed => _currentSpeed;

  static Vector2 _applyLaunchImperfection(Vector2 velocity) {
    const maxOffset = 5 * math.pi / 180;

    final offset = (_rng.nextDouble() * 2 - 1) * maxOffset;

    final cosA = math.cos(offset);
    final sinA = math.sin(offset);

    return Vector2(
      velocity.x * cosA - velocity.y * sinA,
      velocity.x * sinA + velocity.y * cosA,
    );
  }

  void setSpeed(double newSpeed) {
    if (newSpeed == _currentSpeed) return;

    _currentSpeed = newSpeed;
    _velocity.normalize();
    _velocity.scale(_currentSpeed);
  }

  void reflectOffDeflector(Vector2 reflectedVelocity) {
    _velocity
      ..setFrom(reflectedVelocity)
      ..normalize()
      ..scale(_currentSpeed);

    _applyBounceDeviation();
  }

  void _spawnTrail() {
    final game = _gameRef;
    if (game == null || _currentSpeed <= 0) return;

    // Direction of travel
    final dir = _velocity.normalized();

    // === Spawn directly from the visual tail of the bullet ===
    // Use half the sprite width to ensure it's at the back edge
    final spawnPosition = position - dir * (size.x * 0.6);

    // Optional: tiny perpendicular jitter for a more natural "fiery" look
    // final perp = Vector2(-dir.y, dir.x);
    // spawnPosition.addScaled(perp, (_rng.nextDouble() - 0.5) * 3.0);

    final color = getTrailColor(
      game.waveManager!.currentWave.value,
      _currentSpeed,
      _currentSpeed, // maxSpeed is the same as currentSpeed here
    );

    game.world.add(
      FireParticle(
        position: spawnPosition,
        velocity: _velocity.clone(),
        color: color,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await Sprite.load('bullet_sprite.png');
    add(RectangleHitbox());

    SoundService.playBulletFire();
  }

  @override
  void onMount() {
    super.onMount();
    _gameRef = findGame() as OneBulletGame?;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // === Move the bullet FIRST ===
    position += _velocity * dt;

    // Update angle based on new position/velocity
    angle = math.atan2(_velocity.y, _velocity.x);

    // === Then spawn trail at the NEW position ===
    _trailTimer += dt;
    if (_trailTimer > 0.02) {
      _spawnTrail();
      _trailTimer = 0;
    }

    _elapsedTime += dt;

    _handleWallBounce();
  }

  void _handleWallBounce() {
    if (_gameRef == null || _gameRef!.arenaBoundary == null) return;

    final bounds = _gameRef!.arenaBoundary!.getBoundsWithInset(size.x / 2);

    bool bounced = false;

    if (position.x <= bounds.left) {
      position.x = bounds.left;
      _velocity.x = _velocity.x.abs();
      bounced = true;
    } else if (position.x >= bounds.right) {
      position.x = bounds.right;
      _velocity.x = -_velocity.x.abs();
      bounced = true;
    }

    if (position.y <= bounds.top) {
      position.y = bounds.top;
      _velocity.y = _velocity.y.abs();
      bounced = true;
    } else if (position.y >= bounds.bottom) {
      position.y = bounds.bottom;
      _velocity.y = -_velocity.y.abs();
      bounced = true;
    }

    if (bounced) {
      final timeSinceLastEffect = _elapsedTime - _lastBounceEffectTime;

      if (timeSinceLastEffect >= _bounceEffectCooldown) {
        _lastBounceEffectTime = _elapsedTime;
        SoundService.playBulletBounce();
        _triggerHaptics();
      }

      _applyBounceDeviation();
    }
  }

  Future<void> _triggerHaptics() async {
    if (!SettingsService.hapticsEnabled.value || kIsWeb) return;

    final canVibrate = _canVibrate ??= (await Vibration.hasVibrator());

    if (canVibrate) {
      Vibration.vibrate(duration: 50, amplitude: 20);
    }
  }

  void _applyBounceDeviation() {
    _bounceCount++;

    _perpendicular
      ..setValues(-_velocity.y, _velocity.x)
      ..normalize();

    final bias =
        math.sin(_bounceCount * 1.618) * _perpBiasStrength * _currentSpeed;

    _velocity.addScaled(_perpendicular, bias);

    _velocity.normalize();
    _velocity.scale(_currentSpeed);

    _breakAxisAlignment();
  }

  void _breakAxisAlignment() {
    final vxAbs = _velocity.x.abs() / _currentSpeed;
    final vyAbs = _velocity.y.abs() / _currentSpeed;

    bool needsRenormalize = false;

    if (vyAbs < _axisEpsilon) {
      final sign = (_bounceCount % 2 == 0) ? 1.0 : -1.0;
      _velocity.y = _axisEpsilon * _currentSpeed * sign;
      needsRenormalize = true;
    }

    if (vxAbs < _axisEpsilon) {
      final sign = (_bounceCount % 2 == 0) ? 1.0 : -1.0;
      _velocity.x = _axisEpsilon * _currentSpeed * sign;
      needsRenormalize = true;
    }

    if (needsRenormalize) {
      _velocity.normalize();
      _velocity.scale(_currentSpeed);
    }
  }
}

class FireParticle extends CircleComponent {
  FireParticle({
    required Vector2 position,
    required this.velocity, // keep for color/speed reference if needed
    required Color color,
  }) : _baseColor = color,
       super(
         position: position,
         radius: 2 + _rng.nextDouble() * 3,
         anchor: Anchor.center,
         paint: Paint()
           ..color = color
           ..blendMode = BlendMode.screen,
       );

  final Color _baseColor;
  final Vector2 velocity; // we can keep it, but not use for movement

  double life = 0.6; // slightly longer for nicer trail

  static final math.Random _rng = math.Random();

  @override
  void update(double dt) {
    super.update(dt);

    life -= dt;

    // Fade out
    final opacity = (life / 0.6).clamp(0.0, 1.0);
    paint = Paint()
      ..color = _baseColor.withValues(alpha: opacity)
      ..blendMode = BlendMode.screen;

    // Gentle random jitter for fire-like effect
    final jitter = (_rng.nextDouble() - 0.5) * 2.0;
    position += Vector2(jitter, jitter);

    if (life <= 0) {
      removeFromParent();
    }
  }
}

Color getTrailColor(int wave, double speed, double maxSpeed) {
  final t = (speed / maxSpeed).clamp(0.0, 1.0);

  switch (wave) {
    case 1:
      return Color.lerp(Colors.red, Colors.orange, t)!;
    case 2:
      return Color.lerp(const Color(0xFFFF3300), Colors.blue, t)!;
    case 3:
      return Color.lerp(Colors.orange, Colors.yellow, t)!;
    case 4:
      return Color.lerp(Colors.yellow, Colors.white, t)!;
    case 5:
      return Color.lerp(Colors.white, const Color(0xFF00E5FF), t)!;
    case 6:
      return Color.lerp(Colors.white, Colors.white.withOpacity(0.6), t)!;
    default:
      return Colors.orange;
  }
}
