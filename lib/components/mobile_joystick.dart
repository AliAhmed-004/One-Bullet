import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/player.dart';

/// A mobile joystick that appears when the user drags in the bottom
/// quarter of the screen. Controls the player's movement direction.
class MobileJoystick extends PositionComponent with DragCallbacks {
  MobileJoystick({required Player player}) : _player = player;

  /// Reference to the player to control.
  Player _player;

  /// Updates the player reference (used when player respawns after continue).
  void updatePlayer(Player newPlayer) {
    _player = newPlayer;
  }

  /// Radius of the joystick base circle.
  static const double baseRadius = 60.0;

  /// Radius of the joystick knob.
  static const double knobRadius = 25.0;

  /// Maximum distance the knob can move from center.
  static const double maxKnobDistance = 50.0;

  /// Whether the joystick is currently active (being dragged).
  bool _isActive = false;

  /// The center position of the joystick base (in screen coordinates).
  Vector2 _baseCenter = Vector2.zero();

  /// The current position of the knob (in screen coordinates).
  Vector2 _knobPosition = Vector2.zero();

  /// The game's screen size.
  Vector2 _screenSize = Vector2.zero();

  /// Paint for the joystick base.
  final Paint _basePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  /// Paint for the joystick base border.
  final Paint _baseBorderPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  /// Paint for the joystick knob.
  final Paint _knobPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.7)
    ..style = PaintingStyle.fill;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _screenSize = size;

    // Make this component cover the entire screen for drag detection
    this.size = size;
    position = Vector2.zero();
  }

  @override
  void onMount() {
    super.onMount();
    // Set priority to render on top of game elements
    priority = 100;
  }

  /// Checks if the given position is within the joystick activation zone
  /// (bottom quarter of the screen).
  bool _isInActivationZone(Vector2 position) {
    final activationZoneTop = _screenSize.y * 0.75;
    return position.y >= activationZoneTop;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Only activate if the drag starts in the bottom quarter
    if (_isInActivationZone(event.canvasPosition)) {
      _isActive = true;
      _baseCenter = event.canvasPosition.clone();
      _knobPosition = event.canvasPosition.clone();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isActive) return;

    // Calculate the offset from the base center
    final offset = event.canvasEndPosition - _baseCenter;
    final distance = offset.length;

    // Clamp the knob position to the max distance
    if (distance > maxKnobDistance) {
      offset.normalize();
      offset.scale(maxKnobDistance);
    }

    _knobPosition = _baseCenter + offset;

    // Calculate and set the movement direction (normalized)
    if (distance > 5) {
      // Small deadzone to prevent jitter
      final direction = offset.normalized();
      _player.setMovementDirection(direction);
    } else {
      _player.setMovementDirection(Vector2.zero());
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _deactivate();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _deactivate();
  }

  /// Deactivates the joystick and stops player movement.
  void _deactivate() {
    _isActive = false;
    _player.setMovementDirection(Vector2.zero());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Only render if joystick is active
    if (!_isActive) return;

    // Draw the base circle
    canvas.drawCircle(
      Offset(_baseCenter.x, _baseCenter.y),
      baseRadius,
      _basePaint,
    );
    canvas.drawCircle(
      Offset(_baseCenter.x, _baseCenter.y),
      baseRadius,
      _baseBorderPaint,
    );

    // Draw the knob
    canvas.drawCircle(
      Offset(_knobPosition.x, _knobPosition.y),
      knobRadius,
      _knobPaint,
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Only respond to touches in the bottom quarter activation zone
    return _isInActivationZone(point);
  }
}
