import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/score_service.dart';

/// Start screen overlay displayed when the game begins.
/// Responsive design for both mobile and desktop screens.
class StartScreenOverlay extends StatelessWidget {
  const StartScreenOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a smaller (mobile) or larger (desktop) screen
        final isSmallScreen = constraints.maxWidth < 600;
        final titleFontSize = isSmallScreen ? 48.0 : 72.0;
        final subtitleFontSize = isSmallScreen ? 16.0 : 20.0;
        final buttonFontSize = isSmallScreen ? 20.0 : 24.0;
        final instructionFontSize = isSmallScreen ? 12.0 : 14.0;
        final horizontalPadding = isSmallScreen ? 24.0 : 48.0;

        final accentColor = Theme.of(context).colorScheme.secondary;

        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),

            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Settings, High Score & Achievements Buttons (top-right corner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.leaderboard,
                            color: Theme.of(context).colorScheme.secondary,
                            size: titleFontSize * 0.56,
                          ),
                          tooltip: 'Leaderboard',
                          onPressed: () {
                            game.overlays.add(
                              OneBulletGame.leaderboardsOverlayId,
                            );
                            game.overlays.remove(
                              OneBulletGame.startScreenOverlayId,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.emoji_events,
                            color: Theme.of(context).colorScheme.secondary,
                            size: titleFontSize * 0.56,
                          ),
                          tooltip: 'Achievements',
                          onPressed: () {
                            PlayGamesService.instance.showAchievements();
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.secondary,
                            size: titleFontSize * 0.6,
                          ),
                          onPressed: () {
                            game.overlays.add(OneBulletGame.settingsOverlayId);
                            game.overlays.remove(
                              OneBulletGame.startScreenOverlayId,
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 32 : 48),

                    // Game title
                    Text(
                      'ONE BULLET',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: titleFontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'Avoid the bullet that YOU fired!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // High score display
                    ValueListenableBuilder<Duration>(
                      valueListenable: ScoreService.highScore,
                      builder: (context, highScore, _) {
                        // Show encouragement message if no high score yet
                        if (highScore == Duration.zero) {
                          return Text(
                            'Start playing to set a high score!',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                          );
                        }
                        // Show high score badge
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'BEST: ${ScoreService.formatDuration(highScore)}',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 32 : 48),

                    // Start button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => game.startGame(),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 40 : 52,
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSmallScreen ? 'TAP TO START' : 'CLICK TO START',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 48 : 64),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'HOW TO PLAY',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionRow(
                            context: context,
                            icon: Icons.gamepad,
                            text: isSmallScreen
                                ? 'Drag anywhere in the arena to move'
                                : 'Use WASD or Arrow keys to move',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            context: context,
                            icon: Icons.touch_app,
                            text: 'Tap or start moving to fire the bullet',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            context: context,
                            icon: Icons.warning_amber,
                            text: 'The bullet never stops - dodge it!',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            context: context,
                            icon: Icons.timer,
                            text: 'Survive as long as you can',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionRow({
    required IconData icon,
    required String text,
    required double fontSize,
    required Color accentColor,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: fontSize + 6),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
