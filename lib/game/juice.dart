import 'dart:math' as math;

import 'package:flame/components.dart';

/// Screen shake + hit-stop. Driven with real (unscaled) frame time.
class Juice {
  final math.Random _rng = math.Random();

  double _shake = 0; // current amplitude in world px
  double _hitStop = 0; // seconds of freeze left

  /// Amplitude lost per second.
  static const double _shakeDecay = 60;

  /// Hard cap so stacked hits never get nauseating.
  static const double _maxShake = 14;

  /// Game time runs at this fraction during hit-stop (not fully frozen so
  /// particles don't look dead).
  static const double hitStopScale = 0.04;

  bool get isHitStopped => _hitStop > 0;

  void shake(double amplitude) {
    _shake = math.min(_maxShake, math.max(_shake, amplitude));
  }

  void hitStop(double seconds) {
    _hitStop = math.max(_hitStop, seconds);
  }

  /// Advances timers with real [dt]; returns the dt the game should use.
  double tick(double dt) {
    _shake = math.max(0, _shake - _shakeDecay * dt);
    if (_hitStop > 0) {
      _hitStop = math.max(0, _hitStop - dt);
      return dt * hitStopScale;
    }
    return dt;
  }

  /// Camera offset for this frame.
  Vector2 get offset {
    if (_shake <= 0.05) return Vector2.zero();
    return Vector2(
      (_rng.nextDouble() * 2 - 1) * _shake,
      (_rng.nextDouble() * 2 - 1) * _shake,
    );
  }

  void reset() {
    _shake = 0;
    _hitStop = 0;
  }
}
