import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/overlays/achievement_unlocked_overlay.dart';
import 'package:one_bullet/overlays/achievements_overlay.dart';
import 'package:one_bullet/overlays/game_hud_overlay.dart';
import 'package:one_bullet/overlays/game_over_overlay.dart';
import 'package:one_bullet/overlays/pause_overlay.dart';
import 'package:one_bullet/overlays/settings_overlay.dart';
import 'package:one_bullet/overlays/start_screen_overlay.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/themes.dart';

import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for high score storage
  await ScoreService.init();

  // Initialize Google Mobile Ads SDK
  AdService.init();

  // Set up ad configurations
  AdService.setupAds();

  // Initialize settings service
  await SettingsService.init();

  // Initialize Play Games Services
  await PlayGamesService.instance.initialize();

  Flame.device.fullScreen();
  Flame.device.setPortrait();

  runApp(const OneBullet());
}

class OneBullet extends StatelessWidget {
  const OneBullet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      home: GameWidget<OneBulletGame>.controlled(
        gameFactory: OneBulletGame.new,
        overlayBuilderMap: {
          OneBulletGame.startScreenOverlayId: (context, game) =>
              StartScreenOverlay(game: game),
          OneBulletGame.gameHudOverlayId: (context, game) =>
              GameHudOverlay(game: game),
          OneBulletGame.pauseOverlayId: (context, game) =>
              PauseOverlay(game: game),
          OneBulletGame.achievementUnlockedOverlayId: (context, game) =>
              AchievementUnlockedOverlay(
                achievements: game.lastUnlockedAchievements,
                onDismissed: game.onAchievementOverlayComplete,
              ),
          OneBulletGame.gameOverOverlayId: (context, game) =>
              GameOverOverlay(game: game),
          OneBulletGame.settingsOverlayId: (context, game) =>
              SettingsOverlay(game: game),
          OneBulletGame.achievementsOverlayId: (context, game) =>
              AchievementsOverlay(game: game),
        },
      ),
    );
  }
}
