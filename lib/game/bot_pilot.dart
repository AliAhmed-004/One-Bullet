import 'dart:math' as math;

import 'package:flame/components.dart';

/// Debug/recording autopilot that dodges the bullet.
///
/// Pure logic: it is told where the player and bullet are and returns a
/// movement vector. It never touches components, so it can be unit tested.
class BotPilot {
  BotPilot({math.Random? random}) : _rng = random ?? math.Random();

  final math.Random _rng;

  /// Bot tuning parameters.
  double dangerRadius = 90;
  double predictionTime = 0.8;
  double panicRandomness = 0.3;
  double mistakeChance = 0.05;
  double idleSpeed = 0.6;
  double fireDelaySeconds = 2.5;

  final Vector2 _input = Vector2.zero();
  final Vector2 _futureBulletPos = Vector2.zero();
  final Vector2 _panicDirection = Vector2.zero();
  final Vector2 _randomness = Vector2.zero();
  final Vector2 _delayedInput = Vector2.zero();

  double _time = 0;
  double _reactionDelayRemaining = 0;
  double _fireDelayRemaining = 0;

  /// Clears per-run state and re-arms the fire delay.
  void reset() {
    _input.setZero();
    _delayedInput.setZero();
    _reactionDelayRemaining = 0;
    _fireDelayRemaining = fireDelaySeconds;
    _time = 0;
  }

  /// Re-arms the delay before the bot fires its bullet.
  void armFireDelay() {
    _fireDelayRemaining = fireDelaySeconds;
  }

  /// Returns true once the fire delay has elapsed.
  bool canFire(double dt) {
    if (_fireDelayRemaining <= 0) return true;

    _fireDelayRemaining -= dt;
    return _fireDelayRemaining <= 0;
  }

  /// Computes the next movement input.
  ///
  /// Pass [bulletPosition] and [bulletVelocity] only while a bullet is live;
  /// otherwise the bot wanders idly.
  Vector2 next(
    double dt, {
    required Vector2 playerPosition,
    Vector2? bulletPosition,
    Vector2? bulletVelocity,
  }) {
    _time += dt;

    if (_reactionDelayRemaining > 0) {
      _reactionDelayRemaining -= dt;
      _input.setFrom(_delayedInput);
      return _input;
    }

    if (bulletPosition == null || bulletVelocity == null) {
      _setIdle();
      return _input;
    }

    _futureBulletPos
      ..setFrom(bulletPosition)
      ..addScaled(bulletVelocity, predictionTime);

    if (playerPosition.distanceTo(_futureBulletPos) > dangerRadius) {
      _setIdle();
      return _input;
    }

    _panicDirection
      ..setFrom(playerPosition)
      ..sub(_futureBulletPos);

    if (_panicDirection.length2 < 0.0001) {
      _panicDirection
        ..setValues(_rng.nextDouble() * 2 - 1, _rng.nextDouble() * 2 - 1)
        ..normalize();
    }

    _randomness
      ..setValues(_rng.nextDouble() * 2 - 1, _rng.nextDouble() * 2 - 1)
      ..scale(panicRandomness);

    _input
      ..setFrom(_panicDirection)
      ..add(_randomness);

    if (_input.length2 > 0) {
      _input.normalize();
    }

    if (_rng.nextDouble() < mistakeChance) {
      _input.scale(-1);
    }

    // Reaction delay avoids machine-perfect inputs.
    _delayedInput.setFrom(_input);
    _reactionDelayRemaining = 0.03 + _rng.nextDouble() * 0.09;

    return _input;
  }

  void _setIdle() {
    _input.setValues(math.sin(_time * 0.9), math.cos(_time * 0.7 + 1.2));

    if (_input.length2 > 0) {
      _input.normalize();
    }

    _input.scale(idleSpeed);
    _delayedInput.setFrom(_input);
    _reactionDelayRemaining = 0;
  }
}
