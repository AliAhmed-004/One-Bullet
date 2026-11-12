import 'package:flutter/material.dart';
import 'package:one_bullet/theme/neon.dart';

/// Menu / overlay colors. Kept under the old name so existing overlays pick
/// up the neon synthwave look; the values come from [Neon].
class HeatTheme {
  HeatTheme._();

  // ===== CORE PALETTE (legacy names) =====

  static const Color voidBlack = Neon.voidDeep;

  static const Color emberGold = Neon.gold;
  static const Color emberOrange = Neon.orange;
  static const Color moltenRed = Neon.magenta;
  static const Color furnaceCore = Neon.voidHot;

  // ===== BACKGROUND =====

  static Color background(double heat) => Neon.skyTop(heat);

  // ===== PRIMARY ACCENT (UI / BUTTONS) =====

  static Color accent(double heat) => Neon.accent(heat);

  static Color accentSoft(double heat) =>
      Neon.accent(heat).withValues(alpha: 0.7);

  // ===== TEXT =====

  static Color textPrimary(double heat) => Neon.textPrimary;

  static Color textMuted(double heat) => Neon.textMuted;

  // ===== BUTTON SURFACES =====

  static Color surface(double heat) =>
      Color.lerp(const Color(0xFF0E0828), Neon.voidHot, heat)!;

  static Color surfaceGlow(double heat) =>
      Color.lerp(const Color(0xFF1B1050), const Color(0xFF4A1470), heat)!;

  // ===== EFFECT COLORS =====

  static Color emberParticle(double heat) => Neon.accent(heat);

  static Color danger(double heat) =>
      Color.lerp(Neon.orange, const Color(0xFFFF2E5A), heat)!;
}
