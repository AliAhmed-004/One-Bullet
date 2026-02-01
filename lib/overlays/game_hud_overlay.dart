import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/score_service.dart';

/// HUD overlay displaying score (time survived) and pause button.
/// Shown during active gameplay.
class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay({
    required this.game,
    super.key,
  });

  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                // Pause button (top left)
                _buildPauseButton(context),

                // Score/Timer (center)
                Expanded(
                  child: Center(
                    child: _buildTimerDisplay(),
                  ),
                ),

                // Placeholder for symmetry (same width as pause button)
                const SizedBox(width: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => game.pauseGame(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.pause,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return ValueListenableBuilder<Duration>(
      valueListenable: game.survivalTime,
      builder: (context, duration, child) {
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return ValueListenableBuilder<Duration>(
          valueListenable: ScoreService.highScore,
          builder: (context, highScore, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white24,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current timer
                  Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  // High score indicator (only if a high score exists)
                  if (highScore > Duration.zero) ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ScoreService.formatDuration(highScore),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
