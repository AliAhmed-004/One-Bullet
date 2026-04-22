import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Dynamic background that responds to wave progression.
///
/// Features:
/// - Wave-based gradient that shifts from navy → purple → red/magenta → crimson
/// - Subtle grid overlay for spatial reference
/// - Smooth color transitions between waves
class GameBackground extends Component with HasGameReference {
  GameBackground() : super(priority: -1); // Render behind all other components

  late Paint _gradientPaint;
  late Paint _gridPaint;

  // Grid pattern cache
  late Path _gridPath;
  bool _gridInitialized = false;

  static const double _gridSpacing = 50.0;
  static const double _gridAlpha = 0.08; // 8% opacity for subtlety

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize paints
    _gradientPaint = Paint()..style = PaintingStyle.fill;

    _gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: _gridAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gridInitialized = false; // Regenerate grid on resize
  }

  /// Resets the background state (called when game restarts).
  void reset() {
    _gridInitialized = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _ensureGridInitialized();
    _drawGradientBackground(canvas);
    _drawGridOverlay(canvas);
  }

  /// Ensures the grid path is generated based on current screen size.
  void _ensureGridInitialized() {
    if (_gridInitialized) return;

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    _gridPath = Path();

    // Vertical lines
    double x = 0;
    while (x <= screenWidth) {
      _gridPath.moveTo(x, 0);
      _gridPath.lineTo(x, screenHeight);
      x += _gridSpacing;
    }

    // Horizontal lines
    double y = 0;
    while (y <= screenHeight) {
      _gridPath.moveTo(0, y);
      _gridPath.lineTo(screenWidth, y);
      y += _gridSpacing;
    }

    _gridInitialized = true;
  }

  /// Draws the wave-based gradient background.
  void _drawGradientBackground(Canvas canvas) {
    // Always use Wave 1 colors for consistency
    const Color startColor = Color(0xFF0B0B10); // Deep navy black
    const Color endColor = Color(0xFF1A0D2E); // Dark purple

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    final backgroundRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

    // Draw solid base color first
    final basePaint = Paint()
      ..color = startColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(backgroundRect, basePaint);

    // Create radial gradient centered on the screen
    final centerPoint = Offset(screenWidth / 2, screenHeight / 2);

    final maxRadius = (Vector2(screenWidth, screenHeight).length / 2) * 1.2;

    final gradient = ui.Gradient.radial(
      centerPoint,
      maxRadius,
      [startColor, endColor],
      [0.0, 1.0],
      TileMode.clamp,
    );

    _gradientPaint.shader = gradient;

    // Draw gradient using screen-space coordinates
    canvas.drawRect(backgroundRect, _gradientPaint);
  }

  /// Draws the subtle grid overlay.
  void _drawGridOverlay(Canvas canvas) {
    canvas.drawPath(_gridPath, _gridPaint);
  }
}
