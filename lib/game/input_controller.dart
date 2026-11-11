import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:one_bullet/debug/frame_logger.dart';
import 'package:one_bullet/game/bot_pilot.dart';

enum ControlMode { player, bot }

/// Merges keyboard, joystick and (debug) bot input into one movement vector.
class InputController {
  InputController({BotPilot? bot}) : bot = bot ?? BotPilot();

  /// Autopilot used when [mode] is [ControlMode.bot].
  final BotPilot bot;

  /// Active control source for player movement.
  ControlMode mode = ControlMode.player;

  bool get isBot => mode == ControlMode.bot;

  final Vector2 _keyboard = Vector2.zero();
  final Vector2 _joystick = Vector2.zero();
  final Vector2 _movement = Vector2.zero();

  /// Clears per-run input state.
  void reset() {
    _keyboard.setZero();
    _joystick.setZero();
    _movement.setZero();
    bot.reset();
  }

  void setJoystick(Vector2 input) {
    _joystick.setFrom(input);
  }

  void updateKeyboard(Set<LogicalKeyboardKey> keysPressed) {
    _keyboard.setZero();

    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _keyboard.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _keyboard.x += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _keyboard.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _keyboard.y += 1;
    }

    if (_keyboard.length2 > 0) {
      _keyboard.normalize();
    }
  }

  /// Returns this frame's movement vector (length <= 1).
  ///
  /// [bulletPosition]/[bulletVelocity] are only used by the bot and must be
  /// null while no bullet is live.
  Vector2 movement(
    double dt, {
    required Vector2 playerPosition,
    Vector2? bulletPosition,
    Vector2? bulletVelocity,
  }) {
    if (isBot) {
      return bot.next(
        dt,
        playerPosition: playerPosition,
        bulletPosition: bulletPosition,
        bulletVelocity: bulletVelocity,
      );
    }

    _movement
      ..setFrom(_keyboard)
      ..add(_joystick);

    if (_movement.length2 > 1) {
      _movement.normalize();
    }

    return _movement;
  }

  /// Whether movement input may auto-fire the bullet right now.
  bool canAutoFire(double dt) => !isBot || bot.canFire(dt);

  /// Debug-only toggle between player and bot control.
  void toggleBot({required bool playerHasFired}) {
    if (!kDebugMode && !FrameLogger.enabled) return;

    mode = isBot ? ControlMode.player : ControlMode.bot;

    if (isBot && !playerHasFired) {
      bot.armFireDelay();
    }
  }
}
