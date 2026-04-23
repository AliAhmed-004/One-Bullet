import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/theme/heat_theme.dart';

class StartScreenOverlay extends StatelessWidget {
  const StartScreenOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    final heat = 0.15; // static calm menu state

    return Material(
      color: HeatTheme.background(heat),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== SYSTEM MENU BUTTON (TOP RIGHT) =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.menu, color: HeatTheme.accent(heat)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _SystemMenu(game: game),
                      );
                    },
                  ),
                ),
              ),

              // ===== TITLE =====
              Text(
                'ONE BULLET',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: HeatTheme.textPrimary(heat),
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 40),

              // ===== START BUTTON =====
              GestureDetector(
                onTap: () => game.startGame(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: HeatTheme.surface(heat),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HeatTheme.accent(heat),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HeatTheme.accent(heat).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'START',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: HeatTheme.accent(heat),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ===== HIGH SCORE =====
              ValueListenableBuilder<Duration>(
                valueListenable: ScoreService.highScore,
                builder: (context, score, _) {
                  if (score == Duration.zero) {
                    return Text(
                      'No survival record yet',
                      style: TextStyle(color: HeatTheme.textMuted(heat)),
                    );
                  }

                  return Text(
                    'Best: ${ScoreService.formatDuration(score)}',
                    style: TextStyle(
                      color: HeatTheme.emberGold,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // ===== MINIMAL FOOTER =====
              Text(
                'fire a bullet, survive as long as you can',
                style: TextStyle(
                  color: HeatTheme.textMuted(heat),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),

              // Text(
              //   '',
              //   style: TextStyle(
              //     color: HeatTheme.textMuted(heat),
              //     fontSize: 12,
              //     letterSpacing: 1.2,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemMenu extends StatelessWidget {
  const _SystemMenu({required this.game});

  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    final heat = 0.2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: HeatTheme.surface(heat),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: HeatTheme.accent(heat).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SystemButton(
            icon: Icons.leaderboard,
            label: "Leaderboard",
            onTap: () {
              Navigator.pop(context);
              game.overlays.add(OneBulletGame.leaderboardsOverlayId);
              game.overlays.remove(OneBulletGame.startScreenOverlayId);
            },
          ),
          const SizedBox(height: 12),

          _SystemButton(
            icon: Icons.emoji_events,
            label: "Achievements",
            onTap: () {
              PlayGamesService.instance.showAchievements();
            },
          ),
          const SizedBox(height: 12),

          _SystemButton(
            icon: Icons.settings,
            label: "Settings",
            onTap: () {
              Navigator.pop(context);
              game.overlays.add(OneBulletGame.settingsOverlayId);
              game.overlays.remove(OneBulletGame.startScreenOverlayId);
            },
          ),
        ],
      ),
    );
  }
}

class _SystemButton extends StatelessWidget {
  const _SystemButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final heat = 0.2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: HeatTheme.surface(heat),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: HeatTheme.accent(heat).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: HeatTheme.accent(heat)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: HeatTheme.textPrimary(heat),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
