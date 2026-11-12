import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/game_config.dart';
import 'package:one_bullet/theme/neon.dart';

class GameBackground extends PositionComponent with HasGameReference {
  GameBackground({this.initialEmberCount = 26});

  final int initialEmberCount;

  final List<_Ember> _embers = [];
  final math.Random _random = math.Random();

  late final Paint _emberPaint;
  late final Paint _backgroundPaint;
  late final Paint _hotPaint;
  late final Paint _gridPaint;
  late final Paint _vignettePaint;

  /// Distance between grid lines in world px.
  static const double _gridSpacing = 56;
  double _gridScroll = 0;

  double _time = 0;
  int _currentWave = 1;

  Rect _screenBounds = Rect.zero;

  void setWave(int wave) {
    _currentWave = wave;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // set priority to a low value to ensure it renders behind all other components
    priority = -100;

    _emberPaint = Paint()..style = PaintingStyle.fill;
    _backgroundPaint = Paint()..style = PaintingStyle.fill;
    _hotPaint = Paint()..style = PaintingStyle.fill;
    _gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _vignettePaint = Paint()..style = PaintingStyle.fill;

    _updateBounds(game.size);
    _initializeEmbers();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateBounds(size);
  }

  void _updateBounds(Vector2 size) {
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    _screenBounds = Rect.fromLTRB(
      -halfWidth,
      -halfHeight,
      halfWidth,
      halfHeight,
    );

    _backgroundPaint.shader = ui.Gradient.linear(
      _screenBounds.topCenter,
      _screenBounds.bottomCenter,
      [Neon.voidDeep, Neon.voidMid],
    );
    _vignettePaint.shader = ui.Gradient.radial(
      _screenBounds.center,
      _screenBounds.longestSide * 0.65,
      [Colors.transparent, Neon.voidDeep.withValues(alpha: 0.85)],
      const [0.45, 1.0],
    );
  }

  void _initializeEmbers() {
    _embers.clear();

    for (int i = 0; i < initialEmberCount; i++) {
      _embers.add(_createRandomEmber());
    }
  }

  _Ember _createRandomEmber() {
    return _Ember(
      position: Vector2(
        _screenBounds.left + _random.nextDouble() * _screenBounds.width,
        _screenBounds.top + _random.nextDouble() * _screenBounds.height,
      ),
      velocity: Vector2(
        (_random.nextDouble() - 0.5) * 6,
        -8 - _random.nextDouble() * 12,
      ),
      size: 1.2 + _random.nextDouble() * 2.2,
      alpha: 0.14 + _random.nextDouble() * 0.18,
      driftOffset: _random.nextDouble() * math.pi * 2,
      colorIndex: _random.nextInt(3),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;

    final targetHeat =
        (_currentWave / 8).clamp(GameConfig.minHeat, GameConfig.maxHeat);
    GameConfig.heat += (targetHeat - GameConfig.heat) * dt * 1.8;

    final speedMultiplier = 1 + (GameConfig.heat * 2.0);
    _gridScroll = (_gridScroll + dt * 10 * speedMultiplier) % _gridSpacing;

    for (final ember in _embers) {
      ember.position += ember.velocity * dt * speedMultiplier;

      ember.position.x +=
          math.sin(_time * 1.6 + ember.driftOffset) * 6 * dt * speedMultiplier;

      if (ember.position.y < _screenBounds.top - 10) {
        ember.position.y = _screenBounds.bottom + 10;
        ember.position.x =
            _screenBounds.left + _random.nextDouble() * _screenBounds.width;
      }

      if (ember.position.x < _screenBounds.left) {
        ember.position.x = _screenBounds.right;
      }

      if (ember.position.x > _screenBounds.right) {
        ember.position.x = _screenBounds.left;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final heat = GameConfig.heat;

    // Sky gradient, tinted warmer with heat.
    canvas.drawRect(_screenBounds, _backgroundPaint);
    _hotPaint.color = Neon.voidHot.withValues(alpha: heat * 0.55);
    canvas.drawRect(_screenBounds, _hotPaint);

    _drawGrid(canvas, heat);

    // Edge vignette keeps focus on the arena.
    canvas.drawRect(_screenBounds, _vignettePaint);

    for (final ember in _embers) {
      final flicker = 0.7 + 0.4 * math.sin(_time * 3 + ember.driftOffset);

      final color = Color.lerp(
        _particleColors[ember.colorIndex],
        Neon.accent(heat),
        heat * 0.6,
      )!;

      final renderSize = ember.size * (1 + heat * 0.3);

      // glow
      _emberPaint.color = color.withValues(
        alpha: ember.alpha * 0.22 * flicker,
      );
      canvas.drawCircle(
        ember.position.toOffset(),
        renderSize * 2.4,
        _emberPaint,
      );

      // core
      _emberPaint.color = color.withValues(alpha: ember.alpha * flicker);
      canvas.drawCircle(ember.position.toOffset(), renderSize, _emberPaint);
    }
  }

  static const List<Color> _particleColors = [
    Neon.cyan,
    Neon.violet,
    Neon.magenta,
  ];

  void _drawGrid(Canvas canvas, double heat) {
    final b = _screenBounds;
    final pulse = 0.5 + 0.5 * math.sin(_time * 1.2);
    _gridPaint.color = Neon.accent(heat).withValues(alpha: 0.07 + pulse * 0.03);

    for (double x = b.left - (b.left % _gridSpacing); x <= b.right; x +=
        _gridSpacing) {
      canvas.drawLine(Offset(x, b.top), Offset(x, b.bottom), _gridPaint);
    }

    // Horizontal lines scroll slowly downward.
    final startY = b.top - _gridSpacing + _gridScroll;
    for (double y = startY; y <= b.bottom; y += _gridSpacing) {
      canvas.drawLine(Offset(b.left, y), Offset(b.right, y), _gridPaint);
    }
  }
}

class _Ember {
  _Ember({
    required this.position,
    required this.velocity,
    required this.size,
    required this.alpha,
    required this.driftOffset,
    required this.colorIndex,
  });

  Vector2 position;
  Vector2 velocity;
  double size;
  double alpha;
  double driftOffset;
  int colorIndex;
}
