import 'package:flutter/material.dart';

/// One-Bullet's Wild West palette: dusty sand, sunset orange, aged parchment
/// and gunmetal. Heat ramps drive the arena, bullet trail and HUD.
///
/// "Heat" (0..1) is the existing difficulty/intensity value: calm = sun-bleached
/// gold, hot = burnt orange then blood red.
class West {
  West._();

  // ---- Ground / backdrop ----
  static const Color dustDeep = Color(0xFF1A0F0A); // near-black brown
  static const Color dustMid = Color(0xFF3B2416); // shadowed earth
  static const Color sand = Color(0xFFC9A26B); // arena floor
  static const Color sandLight = Color(0xFFE3C58E);
  static const Color duskPurple = Color(0xFF4A2C4F); // sunset sky top
  static const Color sunset = Color(0xFFE8743B); // sunset sky horizon

  // ---- Arena floor (dark enough that gold bullets and the player pop) ----
  static const Color floor = Color(0xFF6B4A30);
  static const Color floorHot = Color(0xFF7A3524);

  // ---- Stone ----
  static const Color stone = Color(0xFF8A7A68);
  static const Color stoneDark = Color(0xFF4F443A);
  static const Color stoneLight = Color(0xFFB5A58F);

  // ---- Accents ----
  static const Color gold = Color(0xFFF2B93B);
  static const Color orange = Color(0xFFE8743B);
  static const Color rust = Color(0xFFA8461F);
  static const Color blood = Color(0xFFB3261E);
  static const Color steel = Color(0xFF4FA3B8); // player: reads on warm sand
  static const Color sage = Color(0xFF6E8B5A); // bushes

  // ---- Paper / ink (WANTED posters) ----
  static const Color parchment = Color(0xFFE8D5A8);
  static const Color parchmentDark = Color(0xFFC9B07C);
  static const Color ink = Color(0xFF2B1A10);
  static const Color nail = Color(0xFF5A5148);

  // ---- Text (on dark UI) ----
  static const Color textPrimary = Color(0xFFF5E6C8);
  static const Color textMuted = Color(0xFFA89170);

  static Color _ramp3(Color a, Color b, Color c, double t) {
    final h = t.clamp(0.0, 1.0);
    return h < 0.5
        ? Color.lerp(a, b, h * 2)!
        : Color.lerp(b, c, (h - 0.5) * 2)!;
  }

  /// Main wall / line color: gold -> orange -> blood red.
  static Color accent(double heat) => _ramp3(gold, orange, blood, heat);

  /// Lighter companion of [accent] for highlights.
  static Color accentSoft(double heat) => _ramp3(
    const Color(0xFFFFE08A),
    const Color(0xFFFFA569),
    const Color(0xFFE06A5F),
    heat,
  );

  /// Ground tint: sun-bleached sand warming toward red dusk as heat rises.
  static Color groundTop(double heat) =>
      Color.lerp(sandLight, const Color(0xFFD08A5A), heat)!;
  static Color groundBottom(double heat) =>
      Color.lerp(sand, const Color(0xFF8E4A2E), heat)!;

  /// Bullet trail / halo: gold -> orange -> blood red.
  static Color trail(double heat) => _ramp3(gold, orange, blood, heat);
}
