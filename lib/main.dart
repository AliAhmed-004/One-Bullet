import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/overlays/game_hud_overlay.dart';
import 'package:one_bullet/overlays/game_over_overlay.dart';
import 'package:one_bullet/overlays/leaderboards_overlay.dart';
import 'package:one_bullet/overlays/pause_overlay.dart';
import 'package:one_bullet/overlays/settings_overlay.dart';
import 'package:one_bullet/overlays/start_screen_overlay.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/achievement_service.dart';
import 'package:one_bullet/themes.dart';

import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/services/settings_service.dart';

bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for high score storage
  await ScoreService.init();

  if (_isMobilePlatform) {
    // Initialize Google Mobile Ads SDK
    AdService.init();

    // Set up ad configurations
    AdService.setupAds();
  }

  // Initialize settings service
  await SettingsService.init();

  // Initialize achievements (must be before Play Games for sync to work)
  await AchievementService.instance.init();

  // Initialize Play Games Services (will sync achievements if signed in)
  if (_isMobilePlatform) {
    await PlayGamesService.instance.initialize();
  }

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
          OneBulletGame.gameOverOverlayId: (context, game) =>
              GameOverOverlay(game: game),
          OneBulletGame.settingsOverlayId: (context, game) =>
              SettingsOverlay(game: game),
          OneBulletGame.leaderboardsOverlayId: (context, game) =>
              LeaderboardsOverlay(game: game),
        },
      ),
    );
  }
}
