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
    this.horizontalPadding = 16,
    this.verticalPadding = 12,
  });

  final double topPadding;
  final double bottomPadding;
  final double sidePadding;
  final Color borderColor;
  final double borderWidth;
  final double horizontalPadding;
  final double verticalPadding;

  Rect _arenaBounds = Rect.zero;
  bool _boundsInitialized = false;

  late final Paint _borderPaint;
  late final Paint _outerGlowPaint;
  late final Paint _innerFillPaint;
  late final Paint _accentPaint;
  late final Paint _sparkPaint;
  late final Paint _wallImpactPaint;

  static const double _waveHeatSmoothing = 1.8;
  static const double _impactPulseDecay = 5.2;
  static const double _wallEnergyDecay = 4.6;
  static const double _breathingHz = 0.24;

  double _time = 0;
  double _waveHeatTarget = 0.1;
  double _waveHeatCurrent = 0.1;
  double _impactPulse = 0;

  double _leftWallEnergy = 0;
  double _rightWallEnergy = 0;
  double _topWallEnergy = 0;
  double _bottomWallEnergy = 0;

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

    _borderPaint = Paint()..style = PaintingStyle.stroke;

    _outerGlowPaint = Paint()..style = PaintingStyle.stroke;

    _innerFillPaint = Paint()..style = PaintingStyle.fill;

    _accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _sparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _wallImpactPaint = Paint()
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
      -halfWidth + sidePadding + horizontalPadding,
      -halfHeight + topPadding + verticalPadding,
      halfWidth - sidePadding - horizontalPadding,
      halfHeight - bottomPadding - verticalPadding,
    );

    _boundsInitialized = true;
  }

  void addImpactSparks({
    required Vector2 position,
    required Vector2 wallNormal,
    required int wave,
  }) {
    _setWaveHeatTargetFromWave(wave);
    _impactPulse = (_impactPulse + 0.24).clamp(0.0, 1.0);

    // _registerWallImpact(wallNormal: wallNormal, impactPosition: position);

    final sparkCount = _getSparkCount(wave);
    final baseSize = wave <= 2
        ? 4.0
        : wave <= 4
        ? 3.0
        : 2.2;

    for (int i = 0; i < sparkCount; i++) {
      final direction = wallNormal.clone()..normalize();

      final angle = (_random.nextDouble() - 0.5) * 1.2;
      direction.rotate(angle);

      final speed = 80 + _random.nextDouble() * (60 + wave * 10);
      final life = 0.25 + _random.nextDouble() * 0.2;

      final sparkColor = Color.lerp(
        const Color(0xFFFFC58F),
        const Color(0xFFFF4938),
        _random.nextDouble() * _waveHeatCurrent,
      )!;

      _sparks.add(
        _SparkParticle(
          position: position.clone(),
          velocity: direction * speed,
          life: life,
          maxLife: life,
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

  void _setWaveHeatTargetFromWave(int wave) {
    final normalized = ((wave - 1) / 5.0).clamp(0.0, 1.0);
    _waveHeatTarget = 0.1 + (normalized * 0.82);
  }

  // void _registerWallImpact({
  //   required Vector2 wallNormal,
  //   required Vector2 impactPosition,
  // }) {
  //   if (wallNormal.x > 0.5) {
  //     _leftWallEnergy = 1.0;
  //     _leftImpactY = impactPosition.y;
  //     return;
  //   }

  //   if (wallNormal.x < -0.5) {
  //     _rightWallEnergy = 1.0;
  //     _rightImpactY = impactPosition.y;
  //     return;
  //   }

  //   if (wallNormal.y > 0.5) {
  //     _topWallEnergy = 1.0;
  //     _topImpactX = impactPosition.x;
  //     return;
  //   }

  //   if (wallNormal.y < -0.5) {
  //     _bottomWallEnergy = 1.0;
  //     _bottomImpactX = impactPosition.x;
  //   }
  // }

  void _updateReactiveState(double dt) {
    _time += dt;

    final heatLerp = (dt * _waveHeatSmoothing).clamp(0.0, 1.0);
    _waveHeatCurrent += (_waveHeatTarget - _waveHeatCurrent) * heatLerp;

    _impactPulse = (_impactPulse - dt * _impactPulseDecay).clamp(0.0, 1.0);

    _leftWallEnergy = (_leftWallEnergy - dt * _wallEnergyDecay).clamp(0.0, 1.0);
    _rightWallEnergy = (_rightWallEnergy - dt * _wallEnergyDecay).clamp(
      0.0,
      1.0,
    );
    _topWallEnergy = (_topWallEnergy - dt * _wallEnergyDecay).clamp(0.0, 1.0);
    _bottomWallEnergy = (_bottomWallEnergy - dt * _wallEnergyDecay).clamp(
      0.0,
      1.0,
    );
  }

  void _updateVisualPaints() {
    final breathing = 0.5 + 0.5 * math.sin(_time * 2 * math.pi * _breathingHz);

    final heat = (_waveHeatCurrent + (_impactPulse * 0.18) + (breathing * 0.04))
        .clamp(0.0, 1.0);

    final border = Color.lerp(
      const Color(0xFF6A8598),
      const Color(0xFFE05E4D),
      heat,
    )!;

    final accent = Color.lerp(
      const Color(0xFF9DB9CA),
      const Color(0xFFFF9679),
      heat,
    )!;

    _innerFillPaint.color = Color.lerp(
      const Color(0xFF0D1822),
      const Color(0xFF261515),
      heat,
    )!.withValues(alpha: 0.18);

    _outerGlowPaint
      ..color = border.withValues(alpha: 0.10 + heat * 0.08)
      ..strokeWidth = 8 + (heat * 2);

    _borderPaint
      ..color = border.withValues(alpha: 0.9)
      ..strokeWidth = 3.2 + heat + (_impactPulse * 0.6);

    _accentPaint
      ..color = accent.withValues(alpha: 0.75)
      ..strokeWidth = 3;

    _wallImpactPaint
      ..color = Color.lerp(
        const Color(0xFFFFB176),
        const Color(0xFFFF5340),
        heat,
      )!
      ..strokeWidth = 4 + heat * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _updateReactiveState(dt);

    final friction = math.pow(0.94, dt * 60).toDouble();

    for (final spark in _sparks) {
      spark.life -= dt;
      spark.position += spark.velocity * dt;
      spark.velocity *= friction;
    }

    _sparks.removeWhere((s) => s.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _updateVisualPaints();

    final rect = _arenaBounds;

    canvas.drawRect(rect, _innerFillPaint);
    canvas.drawRect(rect.inflate(2), _outerGlowPaint);
    canvas.drawRect(rect, _borderPaint);

    // _drawWallImpactAccents(canvas, rect);
    _drawCornerAccents(canvas, rect);
    _drawSparks(canvas);
  }

  // void _drawWallImpactAccents(Canvas canvas, Rect rect) {

  //   const len = 48.0;
  //   if (_leftWallEnergy > 0) {
  //     _wallImpactPaint.color = _wallImpactPaint.color.withValues(
  //       alpha: _leftWallEnergy * 0.6,
  //     );
  //     canvas.drawLine(
  //       Offset(rect.left, _leftImpactY - len),
  //       Offset(rect.left, _leftImpactY + len),
  //       _wallImpactPaint,
  //     );
  //   }

  //   if (_rightWallEnergy > 0) {
  //     _wallImpactPaint.color = _wallImpactPaint.color.withValues(
  //       alpha: _rightWallEnergy * 0.6,
  //     );
  //     canvas.drawLine(
  //       Offset(rect.right, _rightImpactY - len),
  //       Offset(rect.right, _rightImpactY + len),
  //       _wallImpactPaint,
  //     );
  //   }

  //   if (_topWallEnergy > 0) {
  //     _wallImpactPaint.color = _wallImpactPaint.color.withValues(
  //       alpha: _topWallEnergy * 0.6,
  //     );
  //     canvas.drawLine(
  //       Offset(_topImpactX - len, rect.top),
  //       Offset(_topImpactX + len, rect.top),
  //       _wallImpactPaint,
  //     );
  //   }

  //   if (_bottomWallEnergy > 0) {
  //     _wallImpactPaint.color = _wallImpactPaint.color.withValues(
  //       alpha: _bottomWallEnergy * 0.6,
  //     );
  //     canvas.drawLine(
  //       Offset(_bottomImpactX - len, rect.bottom),
  //       Offset(_bottomImpactX + len, rect.bottom),
  //       _wallImpactPaint,
  //     );
  //   }
  // }

  void _drawSparks(Canvas canvas) {
    for (final spark in _sparks) {
      final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);

      _sparkPaint
        ..color = spark.color.withValues(alpha: alpha)
        ..strokeWidth = spark.size;

      final end = spark.position.toOffset();

      final speed = spark.velocity.length;
      final dirX = speed > 0.001 ? spark.velocity.x / speed : 0.0;
      final dirY = speed > 0.001 ? spark.velocity.y / speed : 0.0;

      final start = Offset(end.dx - dirX * 6, end.dy - dirY * 6);

      canvas.drawLine(start, end, _sparkPaint);
    }
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    const len = 20.0;

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
