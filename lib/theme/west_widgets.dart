import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:one_bullet/theme/west.dart';

/// Wild West title face (Rye). Use for logos and headings only.
TextStyle westTitle({
  double size = 28,
  Color color = West.textPrimary,
  double spacing = 2,
  Color? shadow,
}) {
  return TextStyle(
    fontFamily: 'Rye',
    fontSize: size,
    letterSpacing: spacing,
    color: color,
    decoration: TextDecoration.none,
    shadows: shadow == null
        ? null
        : [Shadow(color: shadow, offset: Offset(size * 0.06, size * 0.08))],
  );
}

/// Typewriter body face (Special Elite) for labels, buttons and small text.
TextStyle westText({
  double size = 14,
  Color color = West.textPrimary,
  double spacing = 1.5,
  FontWeight weight = FontWeight.w400,
}) {
  return TextStyle(
    fontFamily: 'SpecialElite',
    fontSize: size,
    letterSpacing: spacing,
    fontWeight: weight,
    color: color,
    decoration: TextDecoration.none,
  );
}

/// Static desert sunset: banded sky, low sun, mesas and cacti. No animation
/// (and no parallax), so it costs one raster pass.
class WestBackdrop extends StatelessWidget {
  const WestBackdrop({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(painter: _DesertPainter()),
        ),
        ?child,
      ],
    );
  }
}

class _DesertPainter extends CustomPainter {
  const _DesertPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.62;

    // Sky.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [West.dustDeep, West.duskPurple, West.rust, West.sunset],
          stops: [0.0, 0.35, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
    );

    // Sun, half sunk into the horizon.
    final sunC = Offset(w * 0.5, horizon);
    final sunR = w * 0.26;
    canvas.drawCircle(
      sunC,
      sunR * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            West.gold.withValues(alpha: 0.45),
            West.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunC, radius: sunR * 1.5)),
    );
    canvas.drawCircle(sunC, sunR, Paint()..color = const Color(0xFFF7C45A));

    // Far mesas.
    _mesas(canvas, w, horizon, const Color(0xFF6B3A2E), 0.10, 3, 11);
    // Near mesas.
    _mesas(canvas, w, horizon, const Color(0xFF3B1F1A), 0.06, 4, 29);

    // Ground.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1710), West.dustDeep],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );

    // Cacti.
    _cactus(canvas, Offset(w * 0.14, horizon + h * 0.05), h * 0.10);
    _cactus(canvas, Offset(w * 0.86, horizon + h * 0.03), h * 0.075);
  }

  void _mesas(
    Canvas canvas,
    double w,
    double horizon,
    Color color,
    double heightFactor,
    int count,
    int seed,
  ) {
    final rnd = math.Random(seed);
    final p = Path()..moveTo(0, horizon);
    var x = -w * 0.05;
    final slot = w * 1.1 / count;
    for (var i = 0; i < count; i++) {
      final top = horizon - w * heightFactor * (0.6 + rnd.nextDouble() * 0.8);
      final mw = slot * (0.55 + rnd.nextDouble() * 0.3);
      final inset = mw * 0.12;
      p
        ..lineTo(x, horizon)
        ..lineTo(x + inset, top)
        ..lineTo(x + mw - inset, top)
        ..lineTo(x + mw, horizon);
      x += slot;
    }
    p
      ..lineTo(w, horizon)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _cactus(Canvas canvas, Offset base, double height) {
    final paint = Paint()
      ..color = const Color(0xFF150B07)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = height * 0.16
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(base, base.translate(0, -height), paint)
      ..drawPath(
        Path()
          ..moveTo(base.dx, base.dy - height * 0.35)
          ..lineTo(base.dx - height * 0.28, base.dy - height * 0.35)
          ..lineTo(base.dx - height * 0.28, base.dy - height * 0.62),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(base.dx, base.dy - height * 0.5)
          ..lineTo(base.dx + height * 0.26, base.dy - height * 0.5)
          ..lineTo(base.dx + height * 0.26, base.dy - height * 0.76),
        paint,
      );
  }

  @override
  bool shouldRepaint(_DesertPainter old) => false;
}

/// Dark leather/plank panel for the main menu sheet.
class PlankPanel extends StatelessWidget {
  const PlankPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2E1D), Color(0xFF2E1B11)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border.all(color: West.gold.withValues(alpha: 0.55), width: 2),
      ),
      child: child,
    );
  }
}

/// Aged WANTED-poster paper: torn edge, double ink border, corner nails.
class WantedPoster extends StatelessWidget {
  const WantedPoster({
    required this.child,
    this.width,
    this.tilt = 0,
    this.seed = 1,
    this.nails = true,
    this.padding = const EdgeInsets.fromLTRB(26, 30, 26, 28),
    super.key,
  });

  final Widget child;
  final double? width;

  /// Rotation in radians.
  final double tilt;

  /// Seeds the torn-edge jitter and paper speckle so each poster differs.
  final int seed;
  final bool nails;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: SizedBox(
        width: width,
        child: CustomPaint(
          painter: _PosterPainter(seed, nails),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _PosterPainter extends CustomPainter {
  _PosterPainter(this.seed, this.nails);

  final int seed;
  final bool nails;

  Path _tornRect(Size s, math.Random rnd) {
    const step = 18.0;
    const jitter = 3.0;
    double j() => (rnd.nextDouble() - 0.5) * 2 * jitter;
    final p = Path()..moveTo(j().abs(), j().abs());
    for (var x = step; x < s.width; x += step) {
      p.lineTo(x, j().abs());
    }
    for (var y = step; y < s.height; y += step) {
      p.lineTo(s.width - j().abs(), y);
    }
    for (var x = s.width - step; x > 0; x -= step) {
      p.lineTo(x, s.height - j().abs());
    }
    for (var y = s.height - step; y > 0; y -= step) {
      p.lineTo(j().abs(), y);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final path = _tornRect(size, rnd);

    // Drop shadow.
    canvas.drawPath(
      path.shift(const Offset(3, 5)),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Paper.
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [West.parchment, West.parchmentDark],
        ).createShader(Offset.zero & size),
    );

    // Stains and speckle (clipped to the paper).
    canvas.save();
    canvas.clipPath(path);
    final stain = Paint()..color = West.rust.withValues(alpha: 0.07);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        20 + rnd.nextDouble() * 50,
        stain,
      );
    }
    final fleck = Paint()..color = West.ink.withValues(alpha: 0.12);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 0.9,
        fleck,
      );
    }
    canvas.restore();

    // Double ink border.
    final ink = Paint()
      ..color = West.ink.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        ink..strokeWidth = 2.5,
      )
      ..drawRect(
        Rect.fromLTWH(15, 15, size.width - 30, size.height - 30),
        ink..strokeWidth = 1,
      );

    if (nails) {
      final nailPaint = Paint()..color = West.nail;
      final shine = Paint()..color = Colors.white.withValues(alpha: 0.5);
      for (final c in [
        const Offset(9, 9),
        Offset(size.width - 9, 9),
        Offset(9, size.height - 9),
        Offset(size.width - 9, size.height - 9),
      ]) {
        canvas
          ..drawCircle(c, 4.5, nailPaint)
          ..drawCircle(c.translate(-1.2, -1.2), 1.4, shine);
      }
    }
  }

  @override
  bool shouldRepaint(_PosterPainter old) =>
      old.seed != seed || old.nails != nails;
}

/// Western button. [onPaper] draws ink-on-parchment for use inside posters;
/// otherwise a gold (primary) or dark plank button for dark screens.
class WestButton extends StatefulWidget {
  const WestButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.color = West.gold,
    this.primary = false,
    this.onPaper = false,
    this.width = 260,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool primary;
  final bool onPaper;
  final double width;
  final VoidCallback? onTap;

  @override
  State<WestButton> createState() => _WestButtonState();
}

class _WestButtonState extends State<WestButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final Color fill;
    final Color fg;
    final Color border;
    if (widget.onPaper) {
      fill = widget.primary ? West.ink : Colors.transparent;
      fg = widget.primary ? West.parchment : West.ink;
      border = West.ink;
    } else if (widget.primary) {
      fill = c;
      fg = West.dustDeep;
      border = West.dustDeep;
    } else {
      fill = const Color(0xFF3B2416);
      fg = c;
      border = c.withValues(alpha: 0.8);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 2),
            boxShadow: widget.onPaper
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 20),
                const SizedBox(width: 10),
              ],
              // Long labels shrink to fit instead of overflowing the row.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: westText(
                      size: 16,
                      color: fg,
                      spacing: 2,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ONE BULLET wordmark with the bullet mascot trailing a dust streak.
class WestLogo extends StatelessWidget {
  const WestLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '~ ONE ~',
          style: westText(size: 20, color: West.sandLight, spacing: 10),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'BULLET',
            style: westTitle(
              size: 64,
              color: West.gold,
              spacing: 4,
              shadow: West.dustDeep,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 26,
          width: 240,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 190,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        West.sand.withValues(alpha: 0),
                        West.sand,
                        West.orange,
                      ],
                    ),
                  ),
                ),
              ),
              Image.asset('assets/images/bullet_sprite.png', width: 62),
            ],
          ),
        ),
      ],
    );
  }
}
