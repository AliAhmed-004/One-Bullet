import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/components/arena_boundary.dart';
import 'package:one_bullet/game_config.dart';
import 'package:one_bullet/theme/west.dart';

/// Purely visual set dressing inside the arena: swaying bushes, a tumbleweed
/// that rolls through now and then, and dust blown by a gusting wind.
/// Child of [ArenaBoundary], so it draws right after the floor and walls and
/// behind every gameplay entity. No collision, no gameplay effect.
class ArenaScenery extends PositionComponent {
  final math.Random _rnd = math.Random(3);
  final math.Random _live = math.Random();

  late final ui.Image _bushBig;
  late final ui.Image _bushSmall;
  late final ui.Image _tumbleweed;
  // Sprites are rasterized once at this scale; _sprite* offsets re-center them.
  static const double _spriteScale = 3;
  static const double _bushPad = 24;
  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.medium;

  final List<_Dust> _dust = [];
  final List<_Bush> _bushes = [];
  late final Paint _dustPaint;

  static const int _dustCount = 36;
  static const double _tumbleRadius = 11;

  double _time = 0;
  double _wind = 16; // px/s, always blowing left to right, gusting
  double _windY = 0;

  // Tumbleweed state.
  bool _tumbling = false;
  double _tumbleTimer = 5;
  Offset _tumblePos = Offset.zero;
  double _tumbleAngle = 0;
  double _tumbleBase = 0;
  double _tumblePhase = 0;

  ArenaBoundary get _arena => parent! as ArenaBoundary;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _dustPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _bushBig = _rasterize(_buildBush(15), _bushPad);
    _bushSmall = _rasterize(_buildBush(10), _bushPad);
    _tumbleweed = _rasterize(_buildTumbleweed(), _bushPad);

    // Anchored by fractions of the arena so they follow resizes.
    _bushes.addAll([
      _Bush(0.04, 0.07, true, 0.0),
      _Bush(0.97, 0.46, false, 1.9),
      _Bush(0.06, 0.93, false, 3.1),
      _Bush(0.94, 0.95, true, 4.4),
    ]);

    final b = _arena.bounds;
    for (var i = 0; i < _dustCount; i++) {
      _dust.add(_newDust(b, randomX: true));
    }
  }

  // ---- Cached art -------------------------------------------------------

  /// Rasterizes [pic] (drawn around the origin) into a (2*pad)^2 image.
  ui.Image _rasterize(ui.Picture pic, double pad) {
    final rec = ui.PictureRecorder();
    Canvas(rec)
      ..scale(_spriteScale)
      ..translate(pad, pad)
      ..drawPicture(pic);
    final out = rec.endRecording();
    final img = out.toImageSync(
      (pad * 2 * _spriteScale).ceil(),
      (pad * 2 * _spriteScale).ceil(),
    );
    out.dispose();
    pic.dispose();
    return img;
  }

  void _drawSprite(Canvas canvas, ui.Image img) {
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      const Rect.fromLTWH(-_bushPad, -_bushPad, _bushPad * 2, _bushPad * 2),
      _spritePaint,
    );
  }

  ui.Picture _buildBush(double r) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    // Twiggy stems.
    final twig = Paint()
      ..color = West.dustDeep.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.38;
      c.drawLine(
        Offset.zero,
        Offset(math.cos(a) * r * 1.1, math.sin(a) * r * 1.1),
        twig,
      );
    }

    // Leaf clumps: dark underside, then lighter tops.
    final dark = Paint()..color = const Color(0xFF3E4A2C);
    final mid = Paint()..color = West.sage;
    final lite = Paint()..color = const Color(0xFF8FA472);
    for (var i = 0; i < 7; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final d = _rnd.nextDouble() * r * 0.6;
      final o = Offset(math.cos(a) * d, math.sin(a) * d * 0.7 - r * 0.2);
      final cr = r * (0.35 + _rnd.nextDouble() * 0.25);
      c
        ..drawCircle(o.translate(0.6, 1.2), cr, dark)
        ..drawCircle(o, cr, mid)
        ..drawCircle(o.translate(-cr * 0.25, -cr * 0.3), cr * 0.5, lite);
    }

    return rec.endRecording();
  }

  ui.Picture _buildTumbleweed() {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final p = Paint()
      ..color = const Color(0xFFB59A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    c.drawCircle(Offset.zero, _tumbleRadius, p);
    for (var i = 0; i < 9; i++) {
      final a1 = _rnd.nextDouble() * math.pi * 2;
      final a2 = a1 + math.pi * (0.6 + _rnd.nextDouble() * 0.8);
      final path = Path()
        ..moveTo(
          math.cos(a1) * _tumbleRadius,
          math.sin(a1) * _tumbleRadius,
        )
        ..quadraticBezierTo(
          (_rnd.nextDouble() - 0.5) * _tumbleRadius,
          (_rnd.nextDouble() - 0.5) * _tumbleRadius,
          math.cos(a2) * _tumbleRadius,
          math.sin(a2) * _tumbleRadius,
        );
      c.drawPath(path, p);
    }
    return rec.endRecording();
  }

  // ---- Dust -------------------------------------------------------------

  _Dust _newDust(Rect b, {bool randomX = false}) {
    return _Dust(
      x: randomX
          ? b.left + _live.nextDouble() * b.width
          : b.left - 10 - _live.nextDouble() * 30,
      y: b.top + _live.nextDouble() * b.height,
      size: 0.9 + _live.nextDouble() * 1.5,
      speed: 0.6 + _live.nextDouble() * 0.9,
      alpha: 0.10 + _live.nextDouble() * 0.16,
      phase: _live.nextDouble() * math.pi * 2,
    );
  }

  // ---- Update / render --------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Slow gusts layered over a steady breeze; a touch stronger when hot.
    final gust = 0.5 + 0.5 * math.sin(_time * 0.35) * math.sin(_time * 0.13 + 1);
    _wind = (14 + 26 * gust) * (1 + GameConfig.heat * 0.6);
    _windY = 4 * math.sin(_time * 0.21);

    final b = _arena.bounds;

    for (var i = 0; i < _dust.length; i++) {
      final d = _dust[i];
      d.x += _wind * d.speed * dt;
      d.y += (_windY + math.sin(_time * 1.4 + d.phase) * 6) * dt;
      if (d.x > b.right + 10 || d.y < b.top - 10 || d.y > b.bottom + 10) {
        _dust[i] = _newDust(b);
      }
    }

    _updateTumbleweed(dt, b);
  }

  void _updateTumbleweed(double dt, Rect b) {
    if (!_tumbling) {
      _tumbleTimer -= dt;
      if (_tumbleTimer <= 0) {
        _tumbling = true;
        _tumbleBase = b.top + 40 + _live.nextDouble() * (b.height - 80);
        _tumblePos = Offset(b.left - _tumbleRadius, _tumbleBase);
        _tumbleAngle = 0;
        _tumblePhase = 0;
      }
      return;
    }

    final speed = _wind * 3.2;
    _tumblePhase += dt * 5;
    final x = _tumblePos.dx + speed * dt;
    // Little hops as it rolls.
    final y = _tumbleBase - (math.sin(_tumblePhase)).abs() * 9;
    _tumblePos = Offset(x, y);
    _tumbleAngle += speed / _tumbleRadius * dt;

    if (x > b.right + _tumbleRadius * 2) {
      _tumbling = false;
      _tumbleTimer = 8 + _live.nextDouble() * 12;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final b = _arena.bounds;
    final heat = GameConfig.heat;

    // Dust streaks, leaning with the wind.
    final lean = _wind * 0.12;
    for (final d in _dust) {
      _dustPaint
        ..color = West.sandLight.withValues(alpha: d.alpha)
        ..strokeWidth = d.size;
      canvas.drawLine(
        Offset(d.x, d.y),
        Offset(d.x - lean * d.speed, d.y - _windY * 0.12),
        _dustPaint,
      );
    }

    // Bushes, swaying with the gusts.
    for (final bush in _bushes) {
      final pos = Offset(
        b.left + b.width * bush.fx,
        b.top + b.height * bush.fy,
      );
      final sway = math.sin(_time * 1.5 + bush.phase) * 0.05 * (0.5 + _wind / 40);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(sway + 0.03 * heat);
      _drawSprite(canvas, bush.big ? _bushBig : _bushSmall);
      canvas.restore();
    }

    if (_tumbling) {
      canvas
        ..save()
        ..translate(_tumblePos.dx, _tumblePos.dy)
        ..rotate(_tumbleAngle);
      _drawSprite(canvas, _tumbleweed);
      canvas.restore();
    }
  }
}

class _Dust {
  _Dust({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.alpha,
    required this.phase,
  });

  double x;
  double y;
  final double size;
  final double speed;
  final double alpha;
  final double phase;
}

class _Bush {
  _Bush(this.fx, this.fy, this.big, this.phase);

  final double fx;
  final double fy;
  final bool big;
  final double phase;
}
