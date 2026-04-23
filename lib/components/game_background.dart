import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameBackground extends Component with HasGameReference {
  GameBackground() : super(priority: -1);

  final math.Random _random = math.Random(42);
  final List<Offset> _noiseDots = [];

  late final Paint _basePaint;
  late final Paint _streakPaint;
  late final Paint _noisePaint;
  late final Paint _vignettePaint;

  bool _noiseInitialized = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _basePaint = Paint();
    _streakPaint = Paint()..strokeWidth = 1.4;
    _noisePaint = Paint()..strokeWidth = 1.2;
    _vignettePaint = Paint();
  }

  void setWave(int wave) {}

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _noiseInitialized = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final size = game.size;
    final rect = Rect.fromLTRB(
      -size.x / 2,
      -size.y / 2,
      size.x / 2,
      size.y / 2,
    );

    _ensureNoise(size);

    _drawBase(canvas, rect, size);
    _drawEnergyStreaks(canvas, size);
    _drawNoise(canvas);
    _drawVignette(canvas, rect, size);
  }

  void _ensureNoise(Vector2 size) {
    if (_noiseInitialized) return;

    _noiseDots.clear();

    for (int i = 0; i < 120; i++) {
      _noiseDots.add(
        Offset(
          -size.x / 2 + _random.nextDouble() * size.x,
          -size.y / 2 + _random.nextDouble() * size.y,
        ),
      );
    }

    _noiseInitialized = true;
  }

  void _drawBase(Canvas canvas, Rect rect, Vector2 size) {
    final gradient = ui.Gradient.linear(
      Offset(-size.x / 2, -size.y / 2),
      Offset(size.x / 2, size.y / 2),
      [const Color(0xFF07080F), const Color(0xFF161C2A), const Color(0xFF0A0C14)],
      [0.0, 0.55, 1.0],
    );

    _basePaint.shader = gradient;
    canvas.drawRect(rect, _basePaint);
  }

  void _drawEnergyStreaks(Canvas canvas, Vector2 size) {
    _streakPaint.color = Colors.white.withValues(alpha: 0.01);
    const spacing = 92.0;

    for (double y = -size.y; y < size.y; y += spacing) {
      canvas.drawLine(
        Offset(-size.x, y),
        Offset(size.x, y + size.x * 0.14),
        _streakPaint,
      );
    }
  }

  void _drawNoise(Canvas canvas) {
    _noisePaint.color = Colors.white.withValues(alpha: 0.01);
    canvas.drawPoints(ui.PointMode.points, _noiseDots, _noisePaint);
  }

  void _drawVignette(Canvas canvas, Rect rect, Vector2 size) {
    const edgeDarkness = 0.36;

    final vignette = ui.Gradient.radial(
      Offset.zero,
      size.length * 0.75,
      [Colors.transparent, Colors.black.withValues(alpha: edgeDarkness)],
      [0.65, 1.0],
    );

    _vignettePaint.shader = vignette;
    canvas.drawRect(rect, _vignettePaint);
  }
}
