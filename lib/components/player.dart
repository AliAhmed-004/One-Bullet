import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/aim_indicator.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/components/player_sprite.dart';
import 'package:one_bullet/debug/frame_logger.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/theme/west.dart';

/// The gunslinger: a top-down cowboy (hat, poncho, neckerchief) whose revolver
/// orbits as the aim indicator. The hitbox is the hat crown (radius 14), which
/// is smaller than the brim, so near misses on the brim are fair.
class Player extends PositionComponent with CollisionCallbacks {
  Player({required Vector2 position, this.skipAimIndicator = false})
    : super(position: position, anchor: Anchor.center, size: Vector2.all(40));

  final bool skipAimIndicator;

  static const double speed = 260.0;

  /// Accent color (neckerchief); also used for the death fragments.
  static const Color playerColor = PlayerSprites.bandana;

  AimIndicator? aimIndicator;
  bool _hasFired = false;

  bool get hasFired => _hasFired || skipAimIndicator;

  /// Aim direction at the moment the shot left the barrel (for recoil/flash).
  final Vector2 _fireDir = Vector2(0, -1);

  void markAsFired() {
    _fireDir.setFrom(aimDirection);
    _fireTimer = _fireDuration;
    _hasFired = true;
    aimIndicator?.removeFromParent();
  }

  Vector2 get aimDirection => aimIndicator?.aimDirection ?? Vector2(0, -1);

  OneBulletGame? _gameRef;

  // ---- Motion state ------------------------------------------------------
  final Vector2 _input = Vector2.zero();
  double _lean = 0; // radians, smoothed toward the move direction
  double _time = 0;
  double _puffTimer = 0;

  static const double _fireDuration = 0.12;
  double _fireTimer = 0;

  final Paint _flashPaint = Paint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Warm the cached art so the first frame doesn't hitch.
    PlayerSprites.body;
    PlayerSprites.revolver;

    // Collision (circular, centered on the hat crown). Attached to the Player
    // itself so `Player.onCollision` is invoked.
    final hitbox = CircleHitbox(radius: 14);
    hitbox.anchor = Anchor.center;
    hitbox.position.setValues(size.x / 2, size.y / 2);
    add(hitbox);

    if (!skipAimIndicator) {
      aimIndicator = AimIndicator(orbitRadius: 26);
      add(aimIndicator!);
    }
  }

  @override
  void onMount() {
    super.onMount();
    _gameRef = findGame() as OneBulletGame?;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_fireTimer > 0) _fireTimer = math.max(0, _fireTimer - dt);

    // Lean into the horizontal movement, easing back to upright when idle.
    final target = _input.x.clamp(-1.0, 1.0) * 0.16;
    _lean += (target - _lean) * math.min(1, dt * 12);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final moving = _input.length2 > 0;
    final bob = moving ? 0.0 : math.sin(_time * 12.5) * 0.8;

    // Recoil: nudge away from the shot direction, fading out.
    final k = _fireTimer / _fireDuration;
    final recoil = k * 2.5;

    canvas
      ..save()
      ..translate(
        size.x / 2 - _fireDir.x * recoil,
        size.y / 2 + bob - _fireDir.y * recoil,
      )
      ..rotate(_lean);
    PlayerSprites.draw(canvas, PlayerSprites.body);
    canvas.restore();

    // Muzzle flash where the revolver pointed when it fired.
    if (_fireTimer > 0) {
      _flashPaint.color = West.gold.withValues(alpha: 0.9 * k);
      canvas.drawCircle(
        Offset(size.x / 2 + _fireDir.x * 36, size.y / 2 + _fireDir.y * 36),
        4 + 6 * k,
        _flashPaint,
      );
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet && !FrameLogger.godMode) {
      _gameRef?.onPlayerDeath();
    }
  }

  void move(Vector2 input, double dt) {
    _input.setFrom(input);

    if (input.length2 > 0) {
      position.addScaled(input, speed * dt);

      // Kick up a little dust behind the boots.
      _puffTimer -= dt;
      if (_puffTimer <= 0) {
        _puffTimer = 0.12;
        final dir = input.normalized();
        parent?.add(
          _DustPuff(
            position: position - dir * 8 + Vector2(0, 10),
            drift: -dir * 14,
          ),
        );
      }
    } else {
      _puffTimer = 0;
    }

    _clampToGameBounds();
  }

  void _clampToGameBounds() {
    if (_gameRef == null || _gameRef!.arenaBoundary == null) return;

    final bounds = _gameRef!.arenaBoundary!.getBoundsWithInset(14);

    position.x = position.x.clamp(bounds.left, bounds.right);
    position.y = position.y.clamp(bounds.top, bounds.bottom);
  }
}

/// Tiny fading dust circle left behind a running player.
class _DustPuff extends PositionComponent {
  _DustPuff({required Vector2 position, required this.drift})
    : super(position: position, anchor: Anchor.center, priority: -1);

  final Vector2 drift;
  static const double _life = 0.4;
  double _age = 0;
  final Paint _paint = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _life) {
      removeFromParent();
      return;
    }
    position.addScaled(drift, dt);
  }

  @override
  void render(Canvas canvas) {
    final t = _age / _life;
    _paint.color = West.sandLight.withValues(alpha: 0.35 * (1 - t));
    canvas.drawCircle(Offset.zero, 2.5 + 4 * t, _paint);
  }
}
