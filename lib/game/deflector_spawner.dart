import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:one_bullet/components/deflector.dart';

/// Spawns and tracks the deflectors alive in the arena.
class DeflectorSpawner {
  DeflectorSpawner({required this.world, math.Random? random})
    : _rng = random ?? math.Random();

  final World world;
  final math.Random _rng;

  /// Hard cap to prevent collision-system overload in long runs.
  static const int maxActive = 16;

  /// Margin from arena edges so deflectors never touch the walls.
  static const double _wallMargin = 60.0;

  final List<Deflector> _active = [];

  int get activeCount => _active.length;

  /// Spawns up to [count] deflectors inside [arenaBounds], respecting [maxActive].
  void spawn(int count, Rect arenaBounds) {
    // Drop stale references before computing the spawn budget.
    _active.removeWhere((d) => d.isRemoving || !d.isMounted);

    final spawnCount = math.min(count, maxActive - _active.length);

    for (var i = 0; i < spawnCount; i++) {
      final deflector = Deflector(
        position: Deflector.randomPositionInArena(
          arenaBounds,
          _rng,
          _wallMargin,
        ),
        angle: Deflector.randomAngle(_rng),
      );

      _active.add(deflector);
      world.add(deflector);
    }
  }

  /// Stops tracking [deflector] (it was destroyed).
  void remove(Deflector deflector) {
    _active.remove(deflector);
  }

  /// Forgets all deflectors (the world is cleared separately).
  void clear() {
    _active.clear();
  }
}
