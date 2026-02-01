import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Visual boundary/arena that shows the playable area.
/// This component draws a border around the play area.
class ArenaBoundary extends PositionComponent with HasGameRef {
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

  /// Gets the arena bounds in world coordinates.
  Rect get bounds {
    _ensureBoundsInitialized();
    return _arenaBounds;
  }

  /// Ensures bounds are calculated (fallback if onGameResize hasn't been called).
  void _ensureBoundsInitialized() {
    if (!_boundsInitialized && isMounted) {
      _updateBounds(gameRef.size);
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
    // Initialize bounds immediately when mounted
    _updateBounds(gameRef.size);
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

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // The arena bounds are already in world coordinates
    // and this component is in the world, so we draw directly
    final renderRect = _arenaBounds;

    // Draw rounded rectangle border
    final rrect = RRect.fromRectAndRadius(renderRect, const Radius.circular(8));
    canvas.drawRRect(rrect, paint);

    // Optional: Add corner accents for a more stylized look
    _drawCornerAccents(canvas, renderRect);
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    final accentPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const accentLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + accentLength),
      Offset(rect.left, rect.top),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + accentLength, rect.top),
      accentPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - accentLength, rect.top),
      Offset(rect.right, rect.top),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + accentLength),
      accentPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - accentLength),
      Offset(rect.left, rect.bottom),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + accentLength, rect.bottom),
      accentPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - accentLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - accentLength),
      accentPaint,
    );
  }
}
