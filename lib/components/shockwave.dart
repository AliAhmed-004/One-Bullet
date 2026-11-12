import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Expanding ring spawned at bounce / break points. Plain srcOver stroke
/// (additive blending was the main raster cost, see perf notes).
class Shockwave extends PositionComponent {
  Shockwave({
    required Vector2 position,
    required this.color,
    this.maxRadius = 46,
    this.duration = 0.28,
    this.strokeWidth = 3,
  }) : super(position: position, anchor: Anchor.center);

  final Color color;
  final double maxRadius;
  final double duration;
  final double strokeWidth;

  double _t = 0;
  final Paint _paint = Paint()..style = PaintingStyle.stroke;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    final eased = 1 - (1 - p) * (1 - p); // ease-out
    _paint
      ..color = color.withValues(alpha: (1 - p) * 0.8)
      ..strokeWidth = strokeWidth * (1 - p) + 0.5;
    canvas.drawCircle(Offset.zero, maxRadius * eased, _paint);
  }
}
