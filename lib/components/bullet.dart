import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/shockwave.dart';
import 'package:one_bullet/debug/frame_logger.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/settings_service.dart';
import 'package:one_bullet/theme/neon.dart';
import 'package:one_bullet/services/sound_service.dart';
import 'package:vibration/vibration.dart';

final math.Random _rng = math.Random(); // reuse, don’t recreate

class Bullet extends SpriteComponent with CollisionCallbacks {
  Bullet({
    required Vector2 position,
    required Vector2 direction,
    double speed = 400.0,
  }) : _velocity = _applyLaunchImperfection(direction.normalized() * speed),
       _baseSpeed = speed,
       _currentSpeed = speed,
       super(position: position, size: Vector2(20, 12), anchor: Anchor.center);

  double _baseSpeed;
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

  double _threatLevel = 0;
  double _threatVisual = 0;
  double _proximityLevel = 0;
  double _proximityVisual = 0;
  late final Paint _threatHaloPaint;

  Vector2 get velocity => _velocity;
  double get currentSpeed => _currentSpeed;

  double _environmentHeat = 0.1;
  double _heatVisual = 0.1;

  void setEnvironmentHeat(double heat) {
    _environmentHeat = heat.clamp(0.0, 1.0);
  }

  void setThreatLevel(double threat) {
    _threatLevel = threat.clamp(0.0, 1.0);
  }

  void setProximityLevel(double proximity) {
    _proximityLevel = proximity.clamp(0.0, 1.0);
  }

  /// Distance at which the bullet starts reading as a threat to the player.
  static const double _maxThreatDistance = 420.0;

  /// Derives threat/proximity visuals from the player's distance.
  /// Pass null when there is no live player (menu, game over).
  void updateThreat(Vector2? playerPosition) {
    if (playerPosition == null) {
      setThreatLevel(0);
      setProximityLevel(0);
      return;
    }

    final proximity =
        (1 - (playerPosition.distanceTo(position) / _maxThreatDistance)).clamp(
          0.0,
          1.0,
        );
    final speed = ((_currentSpeed - 440.0) / 360.0).clamp(0.0, 1.0);

    setProximityLevel(proximity);
    setThreatLevel((proximity * 0.9) + (speed * 0.1));
  }

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
    if (newSpeed == _baseSpeed) return;

    _baseSpeed = newSpeed;

    final dynamicSpeed = _baseSpeed * (1 + _heatVisual * 0.08);
    _currentSpeed = dynamicSpeed;
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

    final dir = _velocity.normalized();

    final spawnPosition = position - dir * (size.x * 0.6);

    final color = getTrailColor(_heatVisual);

    game.world.add(
      FireParticle(
        position: spawnPosition,
        velocity: _velocity.clone(),
        color: color,
        heat: _heatVisual,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _threatHaloPaint = Paint();

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

    final smoothing = (dt * 8).clamp(0.0, 1.0);

    _threatVisual += (_threatLevel - _threatVisual) * smoothing;
    _proximityVisual += (_proximityLevel - _proximityVisual) * smoothing;
    _heatVisual += (_environmentHeat - _heatVisual) * smoothing;

    // subtle heat shimmer scaling
    final heatScale = 1 + (_heatVisual * 0.12);
    size.setValues(20 * heatScale, 12 * (1 + _heatVisual * 0.06));

    // slight heat-driven speed aggression
    final dynamicSpeed = _baseSpeed * (1 + _heatVisual * 0.08);

    _velocity.normalize();
    _velocity.scale(dynamicSpeed);
    _currentSpeed = dynamicSpeed;

    position += _velocity * dt;

    angle = math.atan2(_velocity.y, _velocity.x);

    _trailTimer += dt;
    if (_trailTimer > 0.02) {
      _spawnTrail();
      _trailTimer = 0;
    }

    _elapsedTime += dt;

    _handleWallBounce();
  }

  @override
  void render(Canvas canvas) {
    _renderThreatHalo(canvas);
    super.render(canvas);
  }

  void _renderThreatHalo(Canvas canvas) {
    if (FrameLogger.noBlend) return;
    if (_threatVisual < 0.05 && _heatVisual < 0.05) return;

    final center = Offset(size.x / 2, size.y / 2);

    final radius =
        22 +
        (_threatVisual * 28) +
        (_proximityVisual * 16) +
        (_heatVisual * 12);

    final haloColor = Neon.trail(_heatVisual);

    final coreAlpha =
        (0.16 +
                (_threatVisual * 0.14) +
                (_proximityVisual * 0.12) +
                (_heatVisual * 0.10))
            .clamp(0.0, 0.55);

    final midAlpha = (0.06 + (_threatVisual * 0.08) + (_heatVisual * 0.06))
        .clamp(0.0, 0.30);

    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        haloColor.withValues(alpha: coreAlpha),
        haloColor.withValues(alpha: midAlpha),
        Colors.transparent,
      ],
      const [0.0, 0.55, 1.0],
    );

    _threatHaloPaint.shader = gradient;
    canvas.drawCircle(center, radius, _threatHaloPaint);
  }

  void _handleWallBounce() {
    if (_gameRef == null || _gameRef!.arenaBoundary == null) return;

    final arena = _gameRef!.arenaBoundary!;
    final bounds = arena.getBoundsWithInset(size.x / 2);

    bool bounced = false;

    Vector2? impactPosition;
    Vector2? impactNormal;

    if (position.x <= bounds.left) {
      position.x = bounds.left;
      _velocity.x = _velocity.x.abs();

      bounced = true;
      impactPosition = position.clone();
      impactNormal = Vector2(1, 0); // wall pushes right
    } else if (position.x >= bounds.right) {
      position.x = bounds.right;
      _velocity.x = -_velocity.x.abs();

      bounced = true;
      impactPosition = position.clone();
      impactNormal = Vector2(-1, 0); // wall pushes left
    }

    if (position.y <= bounds.top) {
      position.y = bounds.top;
      _velocity.y = _velocity.y.abs();

      bounced = true;
      impactPosition = position.clone();
      impactNormal = Vector2(0, 1); // wall pushes down
    } else if (position.y >= bounds.bottom) {
      position.y = bounds.bottom;
      _velocity.y = -_velocity.y.abs();

      bounced = true;
      impactPosition = position.clone();
      impactNormal = Vector2(0, -1); // wall pushes up
    }

    if (bounced) {
      final timeSinceLastEffect = _elapsedTime - _lastBounceEffectTime;

      if (timeSinceLastEffect >= _bounceEffectCooldown) {
        _lastBounceEffectTime = _elapsedTime;

        SoundService.playBulletBounce();
        _triggerHaptics();

        final heat = _gameRef!.waveManager == null ? 0.1 : _heatVisual;
        _gameRef!.juice.shake(1.5 + heat * 2.5);
        if (impactPosition != null) {
          _gameRef!.world.add(
            Shockwave(
              position: impactPosition.clone(),
              color: getTrailColor(heat),
              maxRadius: 28 + heat * 18,
            ),
          );
        }
      }

      if (impactPosition != null && impactNormal != null) {
        arena.addImpactSparks(
          position: impactPosition,
          wallNormal: impactNormal,
          wave: _gameRef!.waveManager?.currentWave.value ?? 1,
        );
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
    required this.velocity,
    required Color color,
    required double heat,
  }) : _baseColor = color,
       _heat = heat,
       super(
         position: position,
         radius: 2.2 + _rng.nextDouble() * 2.8 + heat * 1.2,
         anchor: Anchor.center,
         paint: Paint()
           ..color = color
           ..blendMode = BlendMode.srcOver,
       );

  final Color _baseColor;
  final Vector2 velocity;
  final double _heat;

  double life = 0.55;

  static final math.Random _rng = math.Random();

  @override
  void update(double dt) {
    super.update(dt);

    life -= dt;

    final opacity = (life / 0.55).clamp(0.0, 1.0);

    paint.color = _baseColor.withValues(alpha: opacity);

    final jitterStrength = 1.5 + (_heat * 2.5);
    final jitterX = (_rng.nextDouble() - 0.5) * jitterStrength;
    final jitterY = (_rng.nextDouble() - 0.5) * jitterStrength;

    position.x += jitterX;
    position.y += jitterY;

    if (life <= 0) {
      removeFromParent();
    }
  }
}

Color getTrailColor(double heat) {
  final t = heat.clamp(0.0, 1.0);

  return Neon.trail(math.pow(t, 0.75).toDouble());
}
