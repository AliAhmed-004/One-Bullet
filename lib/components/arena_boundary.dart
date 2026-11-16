import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/arena_scenery.dart';
import 'package:one_bullet/game_config.dart';
import 'package:one_bullet/theme/west.dart';

/// The run-down stone arena: packed-earth floor, a ring of broken stone wall
/// and a heat line along the inner edge. Collision is the plain [bounds] rect;
/// the walls are purely visual and live just outside it.
class ArenaBoundary extends PositionComponent with HasGameReference {
  ArenaBoundary({
    required this.topPadding,
    this.bottomPadding = 8,
    this.sidePadding = 8,
    this.horizontalPadding = 16,
    this.verticalPadding = 12,
  });

  final double topPadding;
  final double bottomPadding;
  final double sidePadding;
  final double horizontalPadding;
  final double verticalPadding;

  /// Visual wall thickness outside [bounds].
  static const double _wallThickness = 12;

  Rect _arenaBounds = Rect.zero;
  bool _boundsInitialized = false;

  // Cached static art, rebuilt on resize.
  ui.Image? _staticArt;
  Rect _artRect = Rect.zero;
  static const double _artScale = 2.75;

  late final Paint _floorPaint;
  late final Paint _heatLinePaint;
  late final Paint _sparkPaint;
  final Paint _artPaint = Paint()..filterQuality = FilterQuality.medium;

  static const double _waveHeatSmoothing = 1.8;
  static const double _impactPulseDecay = 5.2;
  static const double _breathingHz = 0.24;

  double _time = 0;
  double _waveHeatTarget = 0.1;
  double _waveHeatCurrent = 0.1;
  double _impactPulse = 0;

  final List<_Chip> _chips = [];
  final math.Random _random = math.Random();

  Rect get bounds {
    _ensureBoundsInitialized();
    return _arenaBounds;
  }

  void _ensureBoundsInitialized() {
    if (!_boundsInitialized && isMounted) {
      _updateBounds(game.size);
    }
  }

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

    _floorPaint = Paint()..style = PaintingStyle.fill;
    _heatLinePaint = Paint()..style = PaintingStyle.stroke;
    _sparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _updateBounds(game.size);

    // Bushes, tumbleweed and drifting dust render right after the arena.
    await add(ArenaScenery());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateBounds(size);
  }

  void _updateBounds(Vector2 gameSize) {
    if (gameSize.x == 0 || gameSize.y == 0) return;

    final halfWidth = gameSize.x / 2;
    final halfHeight = gameSize.y / 2;

    _arenaBounds = Rect.fromLTRB(
      -halfWidth + sidePadding + horizontalPadding,
      -halfHeight + topPadding + verticalPadding,
      halfWidth - sidePadding - horizontalPadding,
      halfHeight - bottomPadding - verticalPadding,
    );

    _boundsInitialized = true;
    _rebuildStaticArt(_arenaBounds);
  }

  // ---- Cached art -------------------------------------------------------

  /// Dark patches, pebbles and cracks on the floor. Seeded so it stays stable
  /// across resizes.
  void _paintFloorDetail(Canvas c, Rect r) {
    final rnd = math.Random(42);

    final patch = Paint()..color = West.dustDeep.withValues(alpha: 0.16);
    for (var i = 0; i < 14; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(
            r.left + rnd.nextDouble() * r.width,
            r.top + rnd.nextDouble() * r.height,
          ),
          width: 50 + rnd.nextDouble() * 90,
          height: 24 + rnd.nextDouble() * 50,
        ),
        patch,
      );
    }

    final light = Paint()..color = West.sandLight.withValues(alpha: 0.10);
    for (var i = 0; i < 10; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(
            r.left + rnd.nextDouble() * r.width,
            r.top + rnd.nextDouble() * r.height,
          ),
          width: 40 + rnd.nextDouble() * 80,
          height: 18 + rnd.nextDouble() * 36,
        ),
        light,
      );
    }

    final pebble = Paint()..color = West.stoneLight.withValues(alpha: 0.35);
    final pebbleDark = Paint()..color = West.dustDeep.withValues(alpha: 0.35);
    for (var i = 0; i < 70; i++) {
      final o = Offset(
        r.left + rnd.nextDouble() * r.width,
        r.top + rnd.nextDouble() * r.height,
      );
      final rad = 0.8 + rnd.nextDouble() * 1.8;
      c
        ..drawCircle(o.translate(0.6, 0.8), rad, pebbleDark)
        ..drawCircle(o, rad, pebble);
    }

    // A few hairline cracks.
    final crack = Paint()
      ..color = West.dustDeep.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 7; i++) {
      var p = Offset(
        r.left + rnd.nextDouble() * r.width,
        r.top + rnd.nextDouble() * r.height,
      );
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 4; s++) {
        p = p.translate(
          (rnd.nextDouble() - 0.3) * 24,
          (rnd.nextDouble() - 0.5) * 18,
        );
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, crack);
    }
  }

  /// Ring of irregular stone blocks, with a few missing (broken) ones.
  void _paintWalls(Canvas c, Rect r) {
    final rnd = math.Random(7);

    // Dark mortar/shadow band behind the stones: four strips, so the arena
    // interior stays untouched.
    final mortar = Paint()..color = West.dustDeep;
    final outer = r.inflate(_wallThickness + 1);
    c
      ..drawRect(Rect.fromLTRB(outer.left, outer.top, outer.right, r.top), mortar)
      ..drawRect(Rect.fromLTRB(outer.left, r.bottom, outer.right, outer.bottom), mortar)
      ..drawRect(Rect.fromLTRB(outer.left, r.top, r.left, r.bottom), mortar)
      ..drawRect(Rect.fromLTRB(r.right, r.top, outer.right, r.bottom), mortar);

    void stone(Rect s, {bool broken = false}) {
      if (broken) {
        // Gap: leave dark, add a little rubble.
        for (var i = 0; i < 3; i++) {
          c.drawCircle(
            s.center.translate(
              (rnd.nextDouble() - 0.5) * s.width,
              (rnd.nextDouble() - 0.5) * s.height,
            ),
            1.2 + rnd.nextDouble() * 1.6,
            Paint()..color = West.stone.withValues(alpha: 0.7),
          );
        }
        return;
      }
      final base = Color.lerp(
        West.stoneDark,
        West.stoneLight,
        0.25 + rnd.nextDouble() * 0.6,
      )!;
      final rr = RRect.fromRectAndRadius(s.deflate(0.8), const Radius.circular(2));
      c
        ..drawRRect(rr, Paint()..color = base)
        // Highlight on the upper-left, shadow on the lower-right.
        ..drawLine(
          rr.outerRect.topLeft.translate(2, 1),
          rr.outerRect.topRight.translate(-2, 1),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.18)
            ..strokeWidth = 1,
        )
        ..drawLine(
          rr.outerRect.bottomLeft.translate(2, -1),
          rr.outerRect.bottomRight.translate(-2, -1),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.28)
            ..strokeWidth = 1,
        );
      // Occasional chip/crack.
      if (rnd.nextDouble() < 0.35) {
        c.drawLine(
          s.center.translate(-s.width * 0.2, -s.height * 0.3),
          s.center.translate(s.width * 0.15, s.height * 0.3),
          Paint()
            ..color = West.dustDeep.withValues(alpha: 0.7)
            ..strokeWidth = 1,
        );
      }
    }

    // Horizontal runs (top & bottom).
    for (final top in [true, false]) {
      var x = r.left - _wallThickness;
      while (x < r.right + _wallThickness) {
        final len = 22 + rnd.nextDouble() * 18;
        final t = _wallThickness - rnd.nextDouble() * 2.5;
        final w = math.min(len, r.right + _wallThickness - x);
        final rect = top
            ? Rect.fromLTWH(x, r.top - t, w, t)
            : Rect.fromLTWH(x, r.bottom, w, t);
        stone(rect, broken: rnd.nextDouble() < 0.07);
        x += len;
      }
    }

    // Vertical runs (left & right), between the horizontal ones.
    for (final left in [true, false]) {
      var y = r.top;
      while (y < r.bottom) {
        final len = 22 + rnd.nextDouble() * 18;
        final t = _wallThickness - rnd.nextDouble() * 2.5;
        final h = math.min(len, r.bottom - y);
        final rect = left
            ? Rect.fromLTWH(r.left - t, y, t, h)
            : Rect.fromLTWH(r.right, y, t, h);
        stone(rect, broken: rnd.nextDouble() < 0.07);
        y += len;
      }
    }

    // Rubble spilling just inside the walls.
    final rubble = Paint()..color = West.stone.withValues(alpha: 0.55);
    for (var i = 0; i < 26; i++) {
      final edge = rnd.nextInt(4);
      final along = rnd.nextDouble();
      final off = 2 + rnd.nextDouble() * 6;
      final o = switch (edge) {
        0 => Offset(r.left + along * r.width, r.top + off),
        1 => Offset(r.left + along * r.width, r.bottom - off),
        2 => Offset(r.left + off, r.top + along * r.height),
        _ => Offset(r.right - off, r.top + along * r.height),
      };
      c.drawCircle(o, 1.2 + rnd.nextDouble() * 2.2, rubble);
    }
  }

  /// Rasterizes floor detail + walls once into a single image so each frame
  /// is one textured draw instead of hundreds of vector ops.
  void _rebuildStaticArt(Rect r) {
    _staticArt?.dispose();

    _artRect = r.inflate(_wallThickness + 2);
    const scale = _artScale;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)
      ..scale(scale)
      ..translate(-_artRect.left, -_artRect.top);
    _paintFloorDetail(c, r);
    _paintWalls(c, r);
    final pic = rec.endRecording();
    _staticArt = pic.toImageSync(
      (_artRect.width * scale).ceil(),
      (_artRect.height * scale).ceil(),
    );
    pic.dispose();
  }

  // ---- Gameplay hooks ---------------------------------------------------

  void addImpactSparks({
    required Vector2 position,
    required Vector2 wallNormal,
    required int wave,
  }) {
    _setWaveHeatTargetFromWave(wave);
    _impactPulse = (_impactPulse + 0.24).clamp(0.0, 1.0);

    // Stone chips and dust, not sparks.
    final count = _getSparkCount(wave);
    final baseSize = wave <= 2
        ? 3.4
        : wave <= 4
        ? 2.8
        : 2.2;

    for (int i = 0; i < count; i++) {
      final direction = wallNormal.clone()..normalize();
      direction.rotate((_random.nextDouble() - 0.5) * 1.2);

      final speed = 70 + _random.nextDouble() * (50 + wave * 10);
      final life = 0.3 + _random.nextDouble() * 0.25;

      final color = Color.lerp(
        West.sandLight,
        West.accentSoft(_waveHeatCurrent),
        0.25 + _random.nextDouble() * 0.35,
      )!;

      _chips.add(
        _Chip(
          position: position.clone(),
          velocity: direction * speed,
          life: life,
          maxLife: life,
          color: color,
          size: baseSize + _random.nextDouble() * 2.0,
        ),
      );
    }
  }

  int _getSparkCount(int wave) {
    if (wave <= 2) return 5;
    if (wave <= 4) return 7;
    return 10;
  }

  void _setWaveHeatTargetFromWave(int wave) {
    final normalized = ((wave - 1) / 5.0).clamp(0.0, 1.0);
    _waveHeatTarget = 0.1 + (normalized * 0.82);
  }

  // ---- Update / render --------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    final heatLerp = (dt * _waveHeatSmoothing).clamp(0.0, 1.0);
    _waveHeatCurrent += (_waveHeatTarget - _waveHeatCurrent) * heatLerp;
    _impactPulse = (_impactPulse - dt * _impactPulseDecay).clamp(0.0, 1.0);

    final friction = math.pow(0.94, dt * 60).toDouble();
    for (final chip in _chips) {
      chip.life -= dt;
      chip.position += chip.velocity * dt;
      chip.velocity *= friction;
    }
    _chips.removeWhere((s) => s.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final breathing = 0.5 + 0.5 * math.sin(_time * 2 * math.pi * _breathingHz);

    // Blend wave heat with the global heat model so the arena tracks the
    // background and bullet.
    final base = math.max(_waveHeatCurrent, GameConfig.heat);
    final heat = (base + (_impactPulse * 0.18) + (breathing * 0.04)).clamp(
      0.0,
      1.0,
    );

    final rect = _arenaBounds;

    // Floor: packed earth, reddening as heat rises.
    _floorPaint.color = Color.lerp(West.floor, West.floorHot, heat)!;
    canvas.drawRect(rect, _floorPaint);

    // Floor detail + broken stone wall ring, pre-rasterized.
    final art = _staticArt;
    if (art != null) {
      canvas.drawImageRect(
        art,
        Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
        _artRect,
        _artPaint,
      );
    }

    // Heat line hugging the inside of the wall.
    _heatLinePaint
      ..color = West.accent(heat).withValues(alpha: 0.55 + _impactPulse * 0.3)
      ..strokeWidth = 2.5 + heat * 1.2 + _impactPulse * 1.5;
    canvas.drawRect(rect.deflate(1.5), _heatLinePaint);

    _drawChips(canvas);
  }

  void _drawChips(Canvas canvas) {
    for (final chip in _chips) {
      final alpha = (chip.life / chip.maxLife).clamp(0.0, 1.0);
      _sparkPaint
        ..color = chip.color.withValues(alpha: alpha)
        ..strokeWidth = chip.size;

      final end = chip.position.toOffset();
      final speed = chip.velocity.length;
      final dirX = speed > 0.001 ? chip.velocity.x / speed : 0.0;
      final dirY = speed > 0.001 ? chip.velocity.y / speed : 0.0;

      canvas.drawLine(
        Offset(end.dx - dirX * 4, end.dy - dirY * 4),
        end,
        _sparkPaint,
      );
    }
  }
}

class _Chip {
  _Chip({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });

  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  Color color;
  double size;
}
