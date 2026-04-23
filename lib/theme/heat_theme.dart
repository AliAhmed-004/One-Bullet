import 'package:flutter/material.dart';

class HeatTheme {
  HeatTheme._();

  // ===== CORE PALETTE =====

  static const Color voidBlack = Color(0xFF0A0807);

  static const Color emberGold = Color(0xFFFFD27A);
  static const Color emberOrange = Color(0xFFFF9A3C);
  static const Color moltenRed = Color(0xFFFF3B1F);
  static const Color furnaceCore = Color(0xFF2A0C08);

  // ===== BACKGROUND =====

  static Color background(double heat) {
    return Color.lerp(const Color(0xFF0A0807), const Color(0xFF220B06), heat)!;
  }

  // ===== PRIMARY ACCENT (UI / BUTTONS) =====

  static Color accent(double heat) {
    return Color.lerp(emberGold, moltenRed, heat)!;
  }

  static Color accentSoft(double heat) {
    return Color.lerp(
      emberGold.withValues(alpha: 0.7),
      moltenRed.withValues(alpha: 0.7),
      heat,
    )!;
  }

  // ===== TEXT =====

  static Color textPrimary(double heat) {
    return Color.lerp(const Color(0xFFFFE9C4), const Color(0xFFFFC2B0), heat)!;
  }

  static Color textMuted(double heat) {
    return Color.lerp(const Color(0xFFB8A08F), const Color(0xFF8A5A4A), heat)!;
  }

  // ===== BUTTON SURFACES =====

  static Color surface(double heat) {
    return Color.lerp(const Color(0xFF14100E), const Color(0xFF2A0C08), heat)!;
  }

  static Color surfaceGlow(double heat) {
    return Color.lerp(const Color(0xFF2A1A14), const Color(0xFF5A1A10), heat)!;
  }

  // ===== EFFECT COLORS =====

  static Color emberParticle(double heat) {
    return Color.lerp(emberGold, moltenRed, heat)!;
  }

  static Color danger(double heat) {
    return Color.lerp(const Color(0xFFFFB24A), const Color(0xFFFF2E2E), heat)!;
  }
}
