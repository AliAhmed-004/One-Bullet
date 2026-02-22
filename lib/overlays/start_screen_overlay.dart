import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
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
          color: Colors.black,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2), // slightly above center
                radius: 1.2,
                colors: [
                  Color(0xFF181820), // subtle inner glow
                  Color(0xFF0B0B10), // outer dark
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Settings Button (top-right corner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
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
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'Avoid the bullet that YOU fired!',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w300,
                        color: Colors.white60,
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
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
                            color: Colors.black.withValues(alpha: 0.4),
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
                                style: TextStyle(
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
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSmallScreen ? 'TAP TO START' : 'CLICK TO START',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'HOW TO PLAY',
                            style: TextStyle(
                              fontSize: instructionFontSize + 2,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionRow(
                            icon: Icons.gamepad,
                            text: isSmallScreen
                                ? 'Drag anywhere in the arena to move'
                                : 'Use WASD or Arrow keys to move',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            icon: Icons.touch_app,
                            text: 'Tap or start moving to fire the bullet',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            icon: Icons.warning_amber,
                            text: 'The bullet never stops - dodge it!',
                            fontSize: instructionFontSize,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
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
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: fontSize + 6),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: Colors.white60,
            ),
          ),
        ),
      ],
    );
  }
}
