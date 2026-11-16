import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A small triangle that revolves around the player, indicating
/// the direction the bullet will be fired.
class AimIndicator extends PositionComponent {
  AimIndicator({
    required this.orbitRadius,
    this.rotationSpeed = 2.0,
    this.color = const Color(0xFFE3C58E),
  }) : super(
         anchor: Anchor.center,
       );

  /// Distance from the player center to the indicator.
  final double orbitRadius;

  /// Speed of rotation in radians per second.
  final double rotationSpeed;

  /// Color of the aim indicator.
  final Color color;

  /// Current angle of rotation (in radians).
  double _currentAngle = 0;

  /// Size of the triangle indicator.
  static const double triangleSize = 15.0;

  /// Returns the current aim direction as a normalized vector.
  Vector2 get aimDirection => Vector2(cos(_currentAngle), sin(_currentAngle));

  /// Returns the current angle in radians.
  double get currentAngle => _currentAngle;

  /// The center offset for orbiting (set based on parent's radius).
  Vector2 _orbitCenter = Vector2.zero();

  /// Cached paints/path to avoid render-loop allocations.
  late final Paint _fillPaint;
  late final Paint _borderPaint;
  late final Path _trianglePath;


  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final halfSize = triangleSize / 2;
    _trianglePath = Path()
      ..moveTo(halfSize, 0)
      ..lineTo(-halfSize, -halfSize)
      ..lineTo(-halfSize, halfSize)
      ..close();
  }

  @override
  void onMount() {
    super.onMount();

    // Compute the orbit center based on the visual center of the parent.
    // The `AimIndicator` is added to the `Player` (a `PositionComponent`),
    // whose visual body is centered in its bounding box. Use the parent's
    // size or child radius when available so the indicator orbits the
    // visual center instead of the parent's top-left.
    final parentComponent = parent;
    if (parentComponent is CircleComponent) {
      // Parent is directly a CircleComponent (rare case)
      _orbitCenter = Vector2.all(parentComponent.radius);
    } else if (parentComponent is PositionComponent) {
      // Parent is most likely the `Player` with an explicit size.
      _orbitCenter = Vector2(
        parentComponent.size.x / 2,
        parentComponent.size.y / 2,
      );
    } else {
      _orbitCenter = Vector2.zero();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Rotate around the player
    _currentAngle += rotationSpeed * dt;

    // Keep angle within 0 to 2*PI range
    if (_currentAngle > 2 * pi) {
      _currentAngle -= 2 * pi;
    }

    // Update position relative to parent's center without allocating new vectors
    position.setValues(
      _orbitCenter.x + cos(_currentAngle) * orbitRadius,
      _orbitCenter.y + sin(_currentAngle) * orbitRadius,
    );

    // Rotate the triangle to point outward
    angle = _currentAngle;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawPath(_trianglePath, _fillPaint);
    canvas.drawPath(_trianglePath, _borderPaint);
  }
}
