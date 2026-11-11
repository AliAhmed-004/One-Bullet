import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_bullet/game/bot_pilot.dart';
import 'package:one_bullet/game/input_controller.dart';

void main() {
  group('InputController', () {
    test('keyboard diagonal is normalised', () {
      final input = InputController()
        ..updateKeyboard({LogicalKeyboardKey.keyD, LogicalKeyboardKey.keyS});
      final v = input.movement(0.016, playerPosition: Vector2.zero());
      expect(v.length, closeTo(1, 1e-6));
      expect(v.x, greaterThan(0));
      expect(v.y, greaterThan(0));
    });

    test('keyboard + joystick are summed then clamped to length 1', () {
      final input = InputController()
        ..updateKeyboard({LogicalKeyboardKey.keyD})
        ..setJoystick(Vector2(1, 0));
      final v = input.movement(0.016, playerPosition: Vector2.zero());
      expect(v.length, closeTo(1, 1e-6));
    });

    test('small joystick deflection is not inflated', () {
      final input = InputController()..setJoystick(Vector2(0.3, 0));
      final v = input.movement(0.016, playerPosition: Vector2.zero());
      expect(v.x, closeTo(0.3, 1e-6));
    });

    test('reset clears input', () {
      final input = InputController()
        ..updateKeyboard({LogicalKeyboardKey.keyW})
        ..setJoystick(Vector2(1, 0))
        ..reset();
      final v = input.movement(0.016, playerPosition: Vector2.zero());
      expect(v.length2, 0);
    });

    test('player mode may always auto-fire', () {
      expect(InputController().canAutoFire(0.016), isTrue);
    });
  });

  group('BotPilot', () {
    test('wanders (bounded) when no bullet is live', () {
      final bot = BotPilot(random: math.Random(1));
      final v = bot.next(0.016, playerPosition: Vector2.zero());
      expect(v.length, lessThanOrEqualTo(bot.idleSpeed + 1e-6));
    });

    test('flees from an imminent bullet', () {
      final bot = BotPilot(random: math.Random(1))..mistakeChance = 0;
      final v = bot.next(
        0.016,
        playerPosition: Vector2.zero(),
        bulletPosition: Vector2(-50, 0),
        bulletVelocity: Vector2.zero(),
      );
      // Bullet is to the left, so the bot should move right.
      expect(v.x, greaterThan(0));
    });

    test('fire delay elapses', () {
      final bot = BotPilot()
        ..fireDelaySeconds = 0.1
        ..reset();
      expect(bot.canFire(0.05), isFalse);
      expect(bot.canFire(0.06), isTrue);
    });
  });
}
