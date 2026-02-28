import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:one_bullet/overlays/achievement_unlocked_overlay.dart';
import 'package:one_bullet/services/achievement_service.dart';
import 'package:one_bullet/themes.dart';

@Preview(name: "Achievement Unlocked Overlay", group: "Overlays")
Widget previewAchievementOverlay() {
  return MaterialApp(
    theme: appLightTheme,
    darkTheme: appDarkTheme,
    home: Scaffold(
      body: AchievementUnlockedOverlay(
        achievements: [
          TimeAchievement(
            id: 'survive_60',
            title: 'One Minute Survivor',
            icon: Icons.timer_outlined,
            requiredSeconds: 60,
          ),
          TimeAchievement(
            id: 'reach_endurance',
            title: 'Endurance Initiate',
            icon: Icons.hourglass_bottom,
            requiredSeconds: 90,
          ),
          TimeAchievement(
            id: 'survive_150',
            title: 'Relentless',
            icon: Icons.local_fire_department_outlined,
            requiredSeconds: 150,
          ),
          TimeAchievement(
            id: 'survive_240',
            title: 'Unbreakable Focus',
            icon: Icons.visibility_outlined,
            requiredSeconds: 240,
          ),
          TimeAchievement(
            id: 'survive_360',
            title: 'Iron Reflex',
            icon: Icons.flash_on_outlined,
            requiredSeconds: 360,
          ),
          TimeAchievement(
            id: 'survive_480',
            title: 'Bullet Master',
            icon: Icons.adjust,
            requiredSeconds: 480,
          ),
        ],
        onDismissed: _noop,
      ),
    ),
  );
}

void _noop() {}
