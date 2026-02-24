import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme definitions (monochrome base color + typography)
///
/// This file exposes `appLightTheme` and `appDarkTheme` which use a
/// single seed/base color and a unified font family for consistent UI.

const Color kBaseColor = Color(0xFF6C63FF); // single accent (adjustable)

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kBaseColor,
    brightness: Brightness.light,
  ),
  primaryColor: kBaseColor,
  scaffoldBackgroundColor: Colors.white,
  textTheme: _buildTextTheme(Brightness.light),
  iconTheme: const IconThemeData(color: Colors.black87),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kBaseColor,
    brightness: Brightness.dark,
  ),
  primaryColor: kBaseColor,
  scaffoldBackgroundColor: const Color(0xFF0B0B10),
  textTheme: _buildTextTheme(Brightness.dark),
  iconTheme: const IconThemeData(color: Colors.white70),
);

TextTheme _buildTextTheme(Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  final base = Typography.material2018().black;
  final color = dark ? Colors.white : Colors.black;

  return GoogleFonts.interTextTheme(
    base,
  ).apply(bodyColor: color, displayColor: color);
}

// Optionally expose the seed color shades if you want explicit variants.
MaterialColor get baseSwatch => MaterialColor(kBaseColor.value, {
  50: Color(0xFFF2F0FF),
  100: Color(0xFFE6E0FF),
  200: Color(0xFFBFB0FF),
  300: Color(0xFF9980FF),
  400: Color(0xFF7F5EFF),
  500: kBaseColor,
  600: Color(0xFF5A45E6),
  700: Color(0xFF4A36CC),
  800: Color(0xFF3928A3),
  900: Color(0xFF281C7A),
});
