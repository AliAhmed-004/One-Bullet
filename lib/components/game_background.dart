import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameBackground extends PositionComponent with HasGameReference {
  GameBackground({this.initialEmberCount = 18});

  final int initialEmberCount;

  final List<_Ember> _embers = [];
  final math.Random _random = math.Random();

  late final Paint _emberPaint;
  late final Paint _backgroundPaint;

  double _time = 0;
  double _heat = 0.1;
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
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;

    final targetHeat = (_currentWave / 8).clamp(0.1, 1.0);
    _heat += (targetHeat - _heat) * dt * 1.8;

    final speedMultiplier = 1 + (_heat * 2.0);

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

    _backgroundPaint.color = Color.lerp(
      const Color(0xFF0B0908), // warm charcoal
      const Color(0xFF1F0C08), // ember-brown black
      _heat,
    )!;

    canvas.drawRect(_screenBounds, _backgroundPaint);

    for (final ember in _embers) {
      final flicker = 0.7 + 0.4 * math.sin(_time * 3 + ember.driftOffset);

      final emberColor = Color.lerp(
        const Color(0xFFFFC94A),
        const Color(0xFFFF3B1F),
        math.pow(_heat, 0.7).toDouble(),
      )!;

      final renderSize = ember.size * (1 + _heat * 0.3);

      // glow
      _emberPaint.color = emberColor.withValues(
        alpha: ember.alpha * 0.22 * flicker,
      );

      canvas.drawCircle(
        ember.position.toOffset(),
        renderSize * 2.2,
        _emberPaint,
      );

      // core
      _emberPaint.color = emberColor.withValues(alpha: ember.alpha * flicker);

      canvas.drawCircle(ember.position.toOffset(), renderSize, _emberPaint);
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
  });

  Vector2 position;
  Vector2 velocity;
  double size;
  double alpha;
  double driftOffset;
}
