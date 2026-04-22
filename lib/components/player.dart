import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/aim_indicator.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/one_bullet_game.dart';

class Player extends PositionComponent with CollisionCallbacks {
  Player({required Vector2 position, this.skipAimIndicator = false})
    : super(position: position, anchor: Anchor.center, size: Vector2.all(40));

  final bool skipAimIndicator;

  static const double speed = 260.0;

  AimIndicator? aimIndicator;
  bool _hasFired = false;

  bool get hasFired => _hasFired || skipAimIndicator;

  void markAsFired() {
    _hasFired = true;
    aimIndicator?.removeFromParent();
  }

  Vector2 get aimDirection => aimIndicator?.aimDirection ?? Vector2(0, -1);

  OneBulletGame? _gameRef;

  // Visual parts
  late CircleComponent _body;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // BODY
    _body = CircleComponent(
      radius: 14,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF1565C0), // deep blue
    );

    // Position the visual body at the center of the Player's bounding
    // box (Player uses size Vector2.all(40)), and attach the hitbox
    // to the body so rendering, collision, and logical position align.
    _body.position.setValues(size.x / 2, size.y / 2);
    add(_body);

    // Collision (still circular for sanity) - attach the hitbox to the
    // `Player` itself so `Player.onCollision` callbacks are invoked.
    final hitbox = CircleHitbox(radius: 14);
    hitbox.anchor = Anchor.center;
    hitbox.position.setValues(size.x / 2, size.y / 2);
    add(hitbox);

    if (!skipAimIndicator) {
      aimIndicator = AimIndicator(orbitRadius: 28);
      add(aimIndicator!);
    }
  }

  @override
  void onMount() {
    super.onMount();
    _gameRef = findGame() as OneBulletGame?;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet) {
      _gameRef?.onPlayerDeath();
    }
  }

  void move(Vector2 input, double dt) {
    if (input.length2 > 0) {
      position.addScaled(input, speed * dt);
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
