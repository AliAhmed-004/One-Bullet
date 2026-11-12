import 'package:flutter/material.dart';

/// One-Bullet's neon synthwave palette. Everything visual (arena, bullet,
/// menus) pulls from here so the game reads as one thing.
///
/// "Heat" (0..1) is the existing difficulty/intensity value: calm = cool
/// cyan/violet, hot = magenta/orange.
class Neon {
  Neon._();

  // ---- Void / backdrop ----
  static const Color voidDeep = Color(0xFF06031A);
  static const Color voidMid = Color(0xFF120838);
  static const Color voidHot = Color(0xFF2B0B4A);

  // ---- Accents ----
  static const Color cyan = Color(0xFF00E5FF);
  static const Color blue = Color(0xFF3D5AFE);
  static const Color violet = Color(0xFFB14CFF);
  static const Color magenta = Color(0xFFFF2BD6);
  static const Color orange = Color(0xFFFF7A3D);
  static const Color gold = Color(0xFFFFD84D);

  // ---- Text ----
  static const Color textPrimary = Color(0xFFF2EAFF);
  static const Color textMuted = Color(0xFF9A8CC4);

  static Color _ramp3(Color a, Color b, Color c, double t) {
    final h = t.clamp(0.0, 1.0);
    return h < 0.5
        ? Color.lerp(a, b, h * 2)!
        : Color.lerp(b, c, (h - 0.5) * 2)!;
  }

  /// Main glow / line color: cyan -> magenta -> orange.
  static Color accent(double heat) => _ramp3(cyan, magenta, orange, heat);

  /// Lighter companion of [accent] for highlights and corner accents.
  static Color accentSoft(double heat) => _ramp3(
    const Color(0xFF9CF6FF),
    const Color(0xFFFF9AEA),
    const Color(0xFFFFB38A),
    heat,
  );

  /// Backdrop gradient stops, top and bottom.
  static Color skyTop(double heat) => Color.lerp(voidDeep, voidHot, heat)!;
  static Color skyBottom(double heat) => Color.lerp(voidMid, voidHot, heat)!;

  /// Bullet trail / halo: gold -> hot orange -> magenta.
  static Color trail(double heat) =>
      _ramp3(gold, orange, magenta, heat);
}
