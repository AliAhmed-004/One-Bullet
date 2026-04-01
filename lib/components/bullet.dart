import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/settings_service.dart';
import 'package:one_bullet/services/sound_service.dart';
import 'package:vibration/vibration.dart';

class Bullet extends SpriteComponent with CollisionCallbacks {
  Bullet({
    required Vector2 position,
    required Vector2 direction,
    this.speed = 400.0,
  }) : _velocity = _applyLaunchImperfection(direction.normalized() * speed),
       _currentSpeed = speed,
       super(
         position: position,
         size: Vector2(32, 16), // adjust based on your sprite
         anchor: Anchor.center,
       );

  /// Applies small random launch offset
  static Vector2 _applyLaunchImperfection(Vector2 velocity) {
    final rng = math.Random();
    const maxOffset = 5 * math.pi / 180;

    final offset = (rng.nextDouble() * 2 - 1) * maxOffset;

    final cosA = math.cos(offset);
    final sinA = math.sin(offset);

    return Vector2(
      velocity.x * cosA - velocity.y * sinA,
      velocity.x * sinA + velocity.y * cosA,
    );
  }

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

  Vector2 get velocity => _velocity;
  double get currentSpeed => _currentSpeed;

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

    // Move bullet
    position += _velocity * dt;

    // Rotate to match velocity direction
    angle = math.atan2(_velocity.y, _velocity.x);
    _elapsedTime += dt;

    _handleWallBounce();
  }

  void _handleWallBounce() {
    if (_gameRef == null || _gameRef!.arenaBoundary == null) return;

    final bounds = _gameRef!.arenaBoundary!.getBoundsWithInset(size.x / 2);

    bool bounced = false;

    // Left / Right
    if (position.x <= bounds.left) {
      position.x = bounds.left;
      _velocity.x = _velocity.x.abs();
      bounced = true;
    } else if (position.x >= bounds.right) {
      position.x = bounds.right;
      _velocity.x = -_velocity.x.abs();
      bounced = true;
    }

    // Top / Bottom
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
