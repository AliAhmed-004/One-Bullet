import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ArenaBoundary extends PositionComponent with HasGameReference {
  ArenaBoundary({
    required this.topPadding,
    this.bottomPadding = 8,
    this.sidePadding = 8,
    this.borderColor = const Color(0xFF64B5F6),
    this.borderWidth = 2,
  });

  final double topPadding;
  final double bottomPadding;
  final double sidePadding;
  final Color borderColor;
  final double borderWidth;

  Rect _arenaBounds = Rect.zero;
  bool _boundsInitialized = false;

  late final Paint _borderPaint;
  late final Paint _accentPaint;
  late final Paint _sparkPaint;

  final List<_SparkParticle> _sparks = [];
  final math.Random _random = math.Random();

  Rect get bounds {
    _ensureBoundsInitialized();
    return _arenaBounds;
  }

  void _ensureBoundsInitialized() {
    if (!_boundsInitialized && isMounted) {
      _updateBounds(game.size);
    }
  }

  Rect getBoundsWithInset(double inset) {
    _ensureBoundsInitialized();
    return Rect.fromLTRB(
      _arenaBounds.left + inset,
      _arenaBounds.top + inset,
      _arenaBounds.right - inset,
      _arenaBounds.bottom - inset,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    _accentPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    _sparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _updateBounds(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateBounds(size);
  }

  void _updateBounds(Vector2 gameSize) {
    if (gameSize.x == 0 || gameSize.y == 0) return;

    final halfWidth = gameSize.x / 2;
    final halfHeight = gameSize.y / 2;

    _arenaBounds = Rect.fromLTRB(
      -halfWidth + sidePadding,
      -halfHeight + topPadding,
      halfWidth - sidePadding,
      halfHeight - bottomPadding,
    );

    _boundsInitialized = true;
  }

  /// Call this whenever bullet hits a wall
  void addImpactSparks({
    required Vector2 position,
    required Vector2 wallNormal,
    required int wave,
  }) {
    final sparkCount = _getSparkCount(wave);
    final sparkColor = _getSparkColor(wave);

    final baseSize = wave <= 2
        ? 4.0
        : wave <= 4
        ? 3.0
        : 2.2;

    for (int i = 0; i < sparkCount; i++) {
      // CORE FIX: emit outward from wall normal
      final direction = wallNormal.clone()..normalize();

      // cone spread around normal
      final angle = (_random.nextDouble() - 0.5) * 1.2;
      direction.rotate(angle);

      final speed = 80 + _random.nextDouble() * (60 + wave * 10);

      _sparks.add(
        _SparkParticle(
          position: position.clone(),
          velocity: direction * speed,
          life: 0.25 + _random.nextDouble() * 0.2,
          maxLife: 0.25 + _random.nextDouble() * 0.2,
          color: sparkColor,
          size: baseSize + _random.nextDouble() * 2.5,
        ),
      );
    }
  }

  int _getSparkCount(int wave) {
    if (wave <= 2) return 5;
    if (wave <= 4) return 7;
    return 10;
  }

  Color _getSparkColor(int wave) {
    if (wave <= 2) {
      return const Color.fromARGB(255, 255, 158, 158);
    } else if (wave <= 4) {
      return const Color.fromARGB(255, 254, 119, 66);
    } else {
      return const Color.fromARGB(255, 255, 2, 2);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final spark in _sparks) {
      spark.life -= dt;
      spark.position += spark.velocity * dt;
      spark.velocity *= 0.94;
    }

    _sparks.removeWhere((s) => s.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = _arenaBounds;

    canvas.drawRect(rect, _borderPaint);
    _drawCornerAccents(canvas, rect);
    _drawSparks(canvas);
  }

  void _drawSparks(Canvas canvas) {
    for (final spark in _sparks) {
      final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);

      _sparkPaint
        ..color = spark.color.withValues(alpha: alpha)
        ..strokeWidth = spark.size;

      final end = spark.position.toOffset();
      final start = (spark.position - spark.velocity.normalized() * 6)
          .toOffset();

      canvas.drawLine(start, end, _sparkPaint);
    }
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    const len = 20.0;

    // corners (unchanged, still clean and minimal)
    canvas.drawLine(
      Offset(rect.left, rect.top + len),
      Offset(rect.left, rect.top),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + len, rect.top),
      _accentPaint,
    );

    canvas.drawLine(
      Offset(rect.right - len, rect.top),
      Offset(rect.right, rect.top),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + len),
      _accentPaint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.bottom - len),
      Offset(rect.left, rect.bottom),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + len, rect.bottom),
      _accentPaint,
    );

    canvas.drawLine(
      Offset(rect.right - len, rect.bottom),
      Offset(rect.right, rect.bottom),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - len),
      _accentPaint,
    );
  }
}

class _SparkParticle {
  _SparkParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });

  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  Color color;
  double size;
}
