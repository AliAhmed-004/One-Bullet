import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:one_bullet/overlays/achievement_unlocked_overlay.dart';
import 'package:one_bullet/themes.dart';

@Preview(name: "Achievement Unlocked Overlay", group: "Overlays")
Widget previewAchievementOverlay() {
  return  MaterialApp(
    theme: appLightTheme,
    darkTheme: appDarkTheme,
    home: Scaffold(
      body: AchievementUnlockedOverlay(
        unlockedAchievementIds: ["Hello Widget Previews!", "Another Achievement"],
        onDismissed: _noop,
      ),
    ),
  );
}

void _noop() {}