import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/score_service.dart';

/// Start screen overlay displayed when the game begins.
/// Responsive design for both mobile and desktop screens.
class StartScreenOverlay extends StatelessWidget {
  const StartScreenOverlay({
    required this.game,
    super.key,
  });

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

        return Material(
          color: Colors.black.withValues(alpha: 0.85),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                            game.overlays.remove(OneBulletGame.startScreenOverlayId);
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
                        letterSpacing: 4,
                        shadows: const [
                          Shadow(
                            color: Colors.orange,
                            blurRadius: 30,
                          ),
                          Shadow(
                            color: Colors.red,
                            blurRadius: 60,
                          ),
                        ],
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
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2,
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
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                  letterSpacing: 1,
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
                            horizontal: isSmallScreen ? 48 : 64,
                            vertical: isSmallScreen ? 16 : 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            isSmallScreen ? 'TAP TO START' : 'CLICK TO START',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
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
                        color: Colors.white.withValues(alpha: 0.1),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionRow(
                            icon: Icons.gamepad,
                            text: isSmallScreen
                                ? 'Use the joystick (bottom of screen) to move'
                                : 'Use WASD or Arrow keys to move',
                            fontSize: instructionFontSize,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            icon: Icons.touch_app,
                            text: 'Tap/Click to fire the bullet',
                            fontSize: instructionFontSize,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            icon: Icons.warning_amber,
                            text: 'The bullet never stops - dodge it!',
                            fontSize: instructionFontSize,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionRow(
                            icon: Icons.timer,
                            text: 'Survive as long as you can',
                            fontSize: instructionFontSize,
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
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.orange,
          size: fontSize + 6,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
