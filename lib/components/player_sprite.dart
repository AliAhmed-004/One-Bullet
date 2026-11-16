import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Cached art for the top-down gunslinger. Everything is rasterized once
/// (3x) and drawn with `drawImageRect`; nothing is replayed per frame.
///
/// All sprites are centered on the origin inside a (2 * [pad])^2 box.
class PlayerSprites {
  PlayerSprites._();

  static const double pad = 24;
  static const double _scale = 3;

  /// Steel-blue neckerchief accent; keeps the player identifiable.
  static const Color bandana = Color(0xFF5BB8D0);

  static ui.Image? _body;
  static ui.Image? _hat;
  static ui.Image? _revolver;

  /// Shadow, poncho, bandana and hat in one image.
  static ui.Image get body => _body ??= _rasterize(_paintBody);

  /// Just the hat (used for the death effect).
  static ui.Image get hat => _hat ??= _rasterize(_paintHat);

  /// Revolver pointing along +x.
  static ui.Image get revolver => _revolver ??= _rasterize(_paintRevolver);

  static final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.medium;

  static ui.Image _rasterize(void Function(Canvas) paint) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)
      ..scale(_scale)
      ..translate(pad, pad);
    paint(c);
    final pic = rec.endRecording();
    final img = pic.toImageSync(
      (pad * 2 * _scale).ceil(),
      (pad * 2 * _scale).ceil(),
    );
    pic.dispose();
    return img;
  }

  /// Draws [img] centered on the canvas origin.
  static void draw(Canvas canvas, ui.Image img, {Paint? paint}) {
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      const Rect.fromLTWH(-pad, -pad, pad * 2, pad * 2),
      paint ?? _spritePaint,
    );
  }

  static Paint tinted(double alpha) => Paint()
    ..filterQuality = FilterQuality.medium
    ..color = Colors.white.withValues(alpha: alpha);

  // ---- Painters (coordinates relative to the sprite center) ---------------

  static void _paintBody(Canvas c) {
    // Ground shadow.
    c.drawOval(
      Rect.fromCenter(center: const Offset(3, 5), width: 34, height: 26),
      Paint()..color = const Color(0x47000000),
    );

    // Poncho / shoulders: wider than tall, with a seam.
    final shoulders = Rect.fromCenter(
      center: const Offset(0, 4),
      width: 30,
      height: 20,
    );
    c
      ..drawOval(shoulders, Paint()..color = const Color(0xFF3F4A2E))
      ..drawOval(
        shoulders.deflate(1.6),
        Paint()..color = const Color(0xFF7D8F5E),
      )
      ..drawLine(
        const Offset(0, -2),
        const Offset(0, 12),
        Paint()
          ..color = const Color(0xFF3F4A2E)
          ..strokeWidth = 1.2,
      );

    // Neckerchief peeking out below the hat.
    final tie = Path()
      ..moveTo(-5, 8)
      ..lineTo(5, 8)
      ..lineTo(0, 16)
      ..close();
    c
      ..drawPath(tie, Paint()..color = bandana)
      ..drawPath(
        tie,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF1A0F0A),
      );

    _paintHat(c);
  }

  static void _paintHat(Canvas c) {
    final brim = Rect.fromCenter(
      center: Offset.zero,
      width: 32,
      height: 28,
    );
    c
      // Brim.
      ..drawOval(brim, Paint()..color = const Color(0xFF2E1B11))
      ..drawOval(
        brim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFC9A26B),
      )
      // Shaded brim underside.
      ..drawOval(
        brim.deflate(3.5),
        Paint()..color = const Color(0xFF3E2718),
      )
      // Crown.
      ..drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFF4A2D1B))
      // Hat band.
      ..drawCircle(
        Offset.zero,
        8.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFFA8461F),
      )
      // Crown highlight.
      ..drawCircle(
        const Offset(-2.4, -2.6),
        4.2,
        Paint()..color = const Color(0xFF6B4630),
      );
  }

  static void _paintRevolver(Canvas c) {
    // Barrel.
    final barrel = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-1, -1.8, 10, 1.8),
      const Radius.circular(1.2),
    );
    c
      ..drawRRect(barrel, Paint()..color = const Color(0xFF9AA5AB))
      ..drawRRect(
        barrel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = const Color(0xFF1A0F0A),
      )
      // Grip.
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-8, -2.4, -2, 2.4),
          const Radius.circular(1.4),
        ),
        Paint()..color = const Color(0xFF6B3E1F),
      )
      // Cylinder.
      ..drawCircle(
        const Offset(-0.5, 0),
        3.6,
        Paint()..color = const Color(0xFF6D777C),
      )
      ..drawCircle(
        const Offset(-0.5, 0),
        3.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = const Color(0xFF1A0F0A),
      )
      // Muzzle shine.
      ..drawCircle(
        const Offset(9, -0.6),
        0.9,
        Paint()..color = const Color(0xFFF5E6C8),
      );
  }
}
