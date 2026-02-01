import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/overlays/game_hud_overlay.dart';
import 'package:one_bullet/overlays/game_over_overlay.dart';
import 'package:one_bullet/overlays/pause_overlay.dart';
import 'package:one_bullet/overlays/start_screen_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Flame.device.fullScreen();
  Flame.device.setPortrait();

  runApp(const OneBullet());
}

class OneBullet extends StatelessWidget {
  const OneBullet({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget<OneBulletGame>.controlled(
      gameFactory: OneBulletGame.new,
      overlayBuilderMap: {
        OneBulletGame.startScreenOverlayId: (context, game) => StartScreenOverlay(
          game: game,
        ),
        OneBulletGame.gameHudOverlayId: (context, game) => GameHudOverlay(
          game: game,
        ),
        OneBulletGame.pauseOverlayId: (context, game) => PauseOverlay(
          game: game,
        ),
        OneBulletGame.gameOverOverlayId: (context, game) => GameOverOverlay(
          game: game,
        ),
      },
    );
  }
}