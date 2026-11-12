import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_bullet/theme/neon.dart';

/// Display font for titles and numbers (falls back to the default font while
/// google_fonts is still fetching / offline).
TextStyle neonDisplay({
  double size = 20,
  Color color = Neon.textPrimary,
  FontWeight weight = FontWeight.w800,
  double spacing = 2,
  Color? glow,
}) {
  return GoogleFonts.orbitron(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    color: color,
    decoration: TextDecoration.none,
    shadows: glow == null
        ? null
        : [
            Shadow(color: glow.withValues(alpha: 0.9), blurRadius: 10),
            Shadow(color: glow.withValues(alpha: 0.5), blurRadius: 24),
          ],
  );
}

/// Animated synthwave backdrop: gradient sky, striped sun, stars and a
/// perspective grid floor scrolling toward the viewer.
class NeonBackdrop extends StatefulWidget {
  const NeonBackdrop({this.heat = 0.1, this.child, super.key});

  final double heat;
  final Widget? child;

  @override
  State<NeonBackdrop> createState() => _NeonBackdropState();
}

class _NeonBackdropState extends State<NeonBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _BackdropPainter(_c.value, widget.heat),
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.t, this.heat);

  final double t;
  final double heat;

  static final List<Offset> _stars = () {
    final r = math.Random(7);
    return List.generate(
      60,
      (_) => Offset(r.nextDouble(), r.nextDouble() * 0.55),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.62;

    // Sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Neon.voidDeep, const Color(0xFF2A0B5C), const Color(0xFF6A1B7A)],
          stops: const [0.0, 0.55, 0.62],
        ).createShader(Offset.zero & size),
    );

    // Stars
    final starPaint = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + i));
      starPaint.color = Colors.white.withValues(alpha: 0.5 * tw);
      canvas.drawCircle(
        Offset(_stars[i].dx * w, _stars[i].dy * h),
        i % 5 == 0 ? 1.6 : 0.9,
        starPaint,
      );
    }

    // Sun with horizontal slats cut out toward the bottom.
    final sunR = w * 0.30;
    final sunC = Offset(w / 2, horizon - sunR * 0.55);
    final sunRect = Rect.fromCircle(center: sunC, radius: sunR);
    canvas.saveLayer(sunRect.inflate(40), Paint());
    canvas.drawCircle(
      sunC,
      sunR * 1.25,
      Paint()
        ..shader = RadialGradient(
          colors: [Neon.magenta.withValues(alpha: 0.35), Colors.transparent],
        ).createShader(Rect.fromCircle(center: sunC, radius: sunR * 1.25)),
    );
    canvas.drawCircle(
      sunC,
      sunR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Neon.gold, Neon.orange, Neon.magenta],
        ).createShader(sunRect),
    );
    final slat = Paint()..blendMode = BlendMode.clear;
    for (var i = 0; i < 6; i++) {
      final y = sunC.dy + sunR * (0.1 + i * 0.15);
      canvas.drawRect(
        Rect.fromLTWH(sunC.dx - sunR, y, sunR * 2, 2.0 + i * 1.6),
        slat,
      );
    }
    canvas.restore();

    // Floor
    final floor = Rect.fromLTRB(0, horizon, w, h);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0838), Neon.voidDeep],
        ).createShader(floor),
    );

    // Horizon glow line
    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..color = Neon.accent(heat).withValues(alpha: 0.9)
        ..strokeWidth = 2,
    );

    // Perspective grid
    final grid = Paint()
      ..color = Neon.accent(heat).withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    final vp = Offset(w / 2, horizon);
    for (var i = -12; i <= 12; i++) {
      canvas.drawLine(vp, Offset(w / 2 + i * w * 0.22, h), grid);
    }
    // Horizontal lines: depth progresses with t, eased so they bunch up
    // near the horizon.
    for (var i = 0; i < 9; i++) {
      final p = ((i + t * 1.0) / 9) % 1.0;
      final y = horizon + (h - horizon) * (p * p);
      grid.color = Neon.accent(heat).withValues(alpha: 0.15 + 0.5 * p);
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.t != t || old.heat != heat;
}

/// Glowing glass panel used for menus and dialogs.
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    required this.child,
    this.color = Neon.violet,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
    super.key,
  });

  final Widget child;
  final Color color;
  final double? width;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF2160A3A), Color(0xF20B0524)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Neon button. [primary] fills with an accent gradient.
class NeonButton extends StatefulWidget {
  const NeonButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.color = Neon.cyan,
    this.primary = false,
    this.width = 260,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool primary;
  final double width;
  final VoidCallback? onTap;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final fg = widget.primary ? Neon.voidDeep : c;

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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: widget.primary
                ? LinearGradient(
                    colors: [c, Color.lerp(c, Neon.magenta, 0.55)!],
                  )
                : null,
            color: widget.primary ? null : c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: _pressed ? 0.55 : 0.32),
                blurRadius: widget.primary ? 22 : 14,
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
              // Long labels (e.g. "CONNECT PLAY GAMES") shrink to fit
              // instead of overflowing the row.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: neonDisplay(
                      size: 15,
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

/// ONE BULLET wordmark with the bullet mascot streaking through it.
class NeonLogo extends StatelessWidget {
  const NeonLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'O N E',
          style: neonDisplay(
            size: 22,
            color: Neon.cyan,
            spacing: 10,
            glow: Neon.cyan,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'BULLET',
            style: neonDisplay(
              size: 62,
              weight: FontWeight.w900,
              spacing: 4,
              color: Colors.white,
              glow: Neon.magenta,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Bullet streaking across with a trail.
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
                        Neon.magenta.withValues(alpha: 0),
                        Neon.magenta,
                        Neon.orange,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Neon.magenta.withValues(alpha: 0.7),
                        blurRadius: 10,
                      ),
                    ],
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
