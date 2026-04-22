import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Visual boundary/arena that shows the playable area.
/// This component draws a border around the play area.
class ArenaBoundary extends PositionComponent with HasGameReference {
  ArenaBoundary({
    required this.topPadding,
    this.bottomPadding = 8,
    this.sidePadding = 8,
    this.borderColor = Colors.white24,
    this.borderWidth = 2,
  });

  /// Padding from the top of the screen (for HUD).
  final double topPadding;

  /// Padding from the bottom of the screen.
  final double bottomPadding;

  /// Padding from the sides of the screen.
  final double sidePadding;

  /// Color of the arena border.
  final Color borderColor;

  /// Width of the border stroke.
  final double borderWidth;

  /// The calculated arena bounds (in world coordinates).
  /// Other components can use this to stay within bounds.
  Rect _arenaBounds = Rect.zero;

  /// Whether bounds have been initialized.
  bool _boundsInitialized = false;

  /// Cached paints to avoid per-frame allocations.
  late final Paint _borderPaint;
  late final Paint _accentPaint;
  late final Paint _glowPaint;

  /// Track last wave for color updates
  int _lastWave = -1;

  /// Gets the arena bounds in world coordinates.
  Rect get bounds {
    _ensureBoundsInitialized();
    return _arenaBounds;
  }

  /// Ensures bounds are calculated (fallback if onGameResize hasn't been called).
  void _ensureBoundsInitialized() {
    if (!_boundsInitialized && isMounted) {
      _updateBounds(game.size);
    }
  }

  /// Gets the arena bounds with an inset (for objects with radius).
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
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    _glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Initialize bounds immediately when mounted
    _updateBounds(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateBounds(size);
  }

  void _updateBounds(Vector2 gameSize) {
    // Avoid updating with zero size
    if (gameSize.x == 0 || gameSize.y == 0) return;

    // Calculate arena bounds in world coordinates (camera centered at 0,0)
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // The arena bounds are already in world coordinates
    // and this component is in the world, so we draw directly
    final renderRect = _arenaBounds;

    // Update colors based on current wave
    final gameRef = findGame();
    final waveNumber = (gameRef as dynamic).waveManager?.currentWave.value ?? 1;
    _updateColorsForWave(waveNumber);

    // Draw glow effect (subtle shadow/glow behind border)
    final rrect = RRect.fromRectAndRadius(renderRect, const Radius.circular(8));
    canvas.drawRRect(rrect, _glowPaint);

    // Draw rounded rectangle border
    canvas.drawRRect(rrect, _borderPaint);

    // Optional: Add corner accents for a more stylized look
    _drawCornerAccents(canvas, renderRect);
  }

  /// Updates border colors based on the current wave.
  void _updateColorsForWave(int wave) {
    if (_lastWave == wave) return; // Skip if already updated for this wave

    _lastWave = wave;

    final (borderColor, glowColor) = _getWaveBorderColors(wave);

    _borderPaint.color = borderColor;
    _glowPaint.color = glowColor.withValues(alpha: 0.4); // Semi-transparent glow
    _accentPaint.color = borderColor.withValues(alpha: 0.7);
  }

  /// Returns the (border, glow) colors for a given wave.
  (Color, Color) _getWaveBorderColors(int wave) {
    const Color lightCyan = Color(0xFF00D4FF);
    const Color softPurple = Color(0xFF7B68EE);
    const Color warmAmber = Color(0xFFFFB700);

    final clampedWave = wave.clamp(1, 6);

    switch (clampedWave) {
      case 1:
      case 2:
        // Calm waves: cyan border with cyan glow
        return (lightCyan, lightCyan);
      case 3:
      case 4:
        // Rising waves: purple accent
        return (softPurple, softPurple);
      case 5:
      case 6:
      default:
        // Intense waves: warm amber/gold
        return (warmAmber, warmAmber);
    }
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    const accentLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + accentLength),
      Offset(rect.left, rect.top),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + accentLength, rect.top),
      _accentPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - accentLength, rect.top),
      Offset(rect.right, rect.top),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + accentLength),
      _accentPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - accentLength),
      Offset(rect.left, rect.bottom),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + accentLength, rect.bottom),
      _accentPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - accentLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      _accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - accentLength),
      _accentPaint,
    );
  }
}
