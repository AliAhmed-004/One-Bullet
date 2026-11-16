import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Visual indicator showing the current wave number above the arena.
/// Flashes when a new wave is approaching.
class WaveIndicator extends PositionComponent {
  WaveIndicator({required this.topPadding}) : super(anchor: Anchor.center);

  /// Padding from the top of the screen.
  final double topPadding;

  /// Current wave number to display.
  int _waveNumber = 1;

  /// Whether the indicator is currently flashing (warning state).
  bool _isFlashing = false;

  /// Flash animation progress (0.0 to 1.0).
  double _flashProgress = 0.0;

  /// Scale animation for wave transitions.
  double _scaleAnimation = 1.0;

  /// Target scale for animation.
  double _targetScale = 1.0;

  /// Text paint configuration.
  late TextPaint _labelPaint;

  /// Flash timer.
  double _flashTimer = 0;

  /// Cached paints to avoid per-frame allocations.
  late final Paint _bgPaint;
  late final Paint _borderPaint;

  /// Cached TextPaint for wave number (style updated only when needed).
  late TextPaint _numberPaint;

  /// Track last flash state to avoid unnecessary style rebuilds.
  bool _lastIsFlashing = false;
  double _lastFlashProgress = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _labelPaint = TextPaint(
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.7),
        letterSpacing: 1,
        decoration: TextDecoration.none,
      ),
    );

    _bgPaint = Paint();
    _borderPaint = Paint()..style = PaintingStyle.stroke;

    _numberPaint = TextPaint(
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
        decoration: TextDecoration.none,
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Position at the top center, below the HUD area
    position = Vector2(0, -size.y / 2 + topPadding + 30);
  }

  /// Updates the displayed wave number.
  void setWave(int wave, {bool flash = false}) {
    if (wave != _waveNumber || flash) {
      _waveNumber = wave;

      if (flash) {
        // Start warning flash
        _isFlashing = true;
        _flashTimer = 0;
      } else {
        // New wave started - do scale pop animation
        _isFlashing = false;
        _scaleAnimation = 1.3;
        _targetScale = 1.0;
      }
    }
  }

  /// Stops the flashing effect.
  void stopFlashing() {
    _isFlashing = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle flash animation
    if (_isFlashing) {
      _flashTimer += dt;
      // Pulsing flash effect (faster pulse as warning continues)
      final pulseSpeed = 4.0 + (_flashTimer * 0.5);
      _flashProgress = (math.sin(_flashTimer * pulseSpeed) + 1) / 2;
    } else {
      _flashProgress = 0;
    }

    // Handle scale animation (smooth lerp)
    if ((_scaleAnimation - _targetScale).abs() > 0.01) {
      _scaleAnimation += (_targetScale - _scaleAnimation) * dt * 8;
    } else {
      _scaleAnimation = _targetScale;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Quantize flash progress to reduce style rebuilds (10 steps).
    final quantizedProgress = (_flashProgress * 10).round() / 10;
    final needsStyleUpdate = _isFlashing != _lastIsFlashing ||
        (_isFlashing && quantizedProgress != _lastFlashProgress);

    if (needsStyleUpdate) {
      _lastIsFlashing = _isFlashing;
      _lastFlashProgress = quantizedProgress;
      _updatePaintStyles(quantizedProgress);
    }

    // Container dimensions
    const containerWidth = 120.0;
    const containerHeight = 50.0;

    // Apply scale animation
    canvas.save();
    canvas.scale(_scaleAnimation, _scaleAnimation);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: containerWidth,
        height: containerHeight,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, _bgPaint);
    canvas.drawRRect(rect, _borderPaint);

    // "WAVE" label
    _labelPaint.render(canvas, 'WAVE', Vector2(0, -12), anchor: Anchor.center);

    // Wave number
    _numberPaint.render(
      canvas,
      '$_waveNumber',
      Vector2(0, 10),
      anchor: Anchor.center,
    );

    canvas.restore();
  }

  /// Updates cached paint styles based on flash state.
  void _updatePaintStyles(double flashProgress) {
    final flashColor = _isFlashing
        ? Color.lerp(const Color(0xFFFF7A3D), const Color(0xFFB3261E), flashProgress)!
        : const Color(0xFFF2B93B);

    _bgPaint.color = flashColor.withValues(
      alpha: _isFlashing ? 0.3 + flashProgress * 0.2 : 0.15,
    );

    _borderPaint
      ..color = flashColor.withValues(
        alpha: _isFlashing ? 0.8 + flashProgress * 0.2 : 0.5,
      )
      ..strokeWidth = _isFlashing ? 2 + flashProgress : 2;

    final numberColor = _isFlashing
        ? Color.lerp(Colors.orange, Colors.red, flashProgress)!
        : Colors.white;

    _numberPaint = TextPaint(
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: numberColor,
        letterSpacing: 2,
        decoration: TextDecoration.none,
        shadows: _isFlashing
            ? [
                Shadow(
                  color: Colors.orange.withValues(alpha: 0.8),
                  blurRadius: 10 + flashProgress * 10,
                ),
              ]
            : null,
      ),
    );
  }
}
