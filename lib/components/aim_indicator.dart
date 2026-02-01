import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A small triangle that revolves around the player, indicating
/// the direction the bullet will be fired.
class AimIndicator extends PositionComponent {
  AimIndicator({
    required this.orbitRadius,
    this.rotationSpeed = 2.0,
    this.color = Colors.red,
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

  @override
  void onMount() {
    super.onMount();

    // Get the parent's radius to calculate the orbit center
    // Child coordinates start at top-left of parent's bounding box,
    // so we need to offset to the visual center
    final parentComponent = parent;
    if (parentComponent is CircleComponent) {
      _orbitCenter = Vector2.all(parentComponent.radius);
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

    // Update position relative to parent's center
    position = _orbitCenter + Vector2(
      cos(_currentAngle) * orbitRadius,
      sin(_currentAngle) * orbitRadius,
    );

    // Rotate the triangle to point outward
    angle = _currentAngle;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a triangle pointing in the direction of movement
    // Centered around (0, 0) since anchor is Anchor.center
    final path = Path();

    // Triangle pointing to the right (will be rotated by the component's angle)
    final halfSize = triangleSize / 2;
    path.moveTo(halfSize, 0); // Tip (pointing outward)
    path.lineTo(-halfSize, -halfSize); // Bottom left
    path.lineTo(-halfSize, halfSize); // Top left
    path.close();

    canvas.drawPath(path, paint);

    // Optional: Add a border for better visibility
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }
}
