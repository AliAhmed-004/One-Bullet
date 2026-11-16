import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/game_config.dart';
import 'package:one_bullet/theme/west.dart';

/// Dusk-tinted ground behind the arena (visible in the margins and HUD strip).
/// Also drives the global [GameConfig.heat] value toward the current wave.
class GameBackground extends PositionComponent with HasGameReference {
  late final Paint _backgroundPaint;
  late final Paint _hotPaint;
  late final Paint _vignettePaint;

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

    _backgroundPaint = Paint()..style = PaintingStyle.fill;
    _hotPaint = Paint()..style = PaintingStyle.fill;
    _vignettePaint = Paint()..style = PaintingStyle.fill;

    _updateBounds(game.size);
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
      [West.dustDeep, West.dustMid],
    );
    _vignettePaint.shader = ui.Gradient.radial(
      _screenBounds.center,
      _screenBounds.longestSide * 0.65,
      [Colors.transparent, West.dustDeep.withValues(alpha: 0.8)],
      const [0.5, 1.0],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    final targetHeat = (_currentWave / 8).clamp(
      GameConfig.minHeat,
      GameConfig.maxHeat,
    );
    GameConfig.heat += (targetHeat - GameConfig.heat) * dt * 1.8;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Ground, tinted toward dusk red with heat.
    canvas.drawRect(_screenBounds, _backgroundPaint);
    _hotPaint.color = West.rust.withValues(alpha: GameConfig.heat * 0.35);
    canvas.drawRect(_screenBounds, _hotPaint);

    canvas.drawRect(_screenBounds, _vignettePaint);
  }
}
