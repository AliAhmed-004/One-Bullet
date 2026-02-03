import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/overlays/wave_indicator_widget.dart';
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause button (left)
                _buildPauseButton(context),

                // Timer and Wave (center)
                Expanded(
                  child: Center(
                    child: _buildTimerAndWaveDisplay(),
                  ),
                ),
              ],
            ),

            // High score (below timer)
            ValueListenableBuilder<Duration>(
              valueListenable: ScoreService.highScore,
              builder: (context, highScore, _) {
                if (highScore <= Duration.zero) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Best: ${ScoreService.formatDuration(highScore)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
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

  Widget _buildTimerAndWaveDisplay() {
    return ValueListenableBuilder<Duration>(
      valueListenable: game.survivalTime,
      builder: (context, duration, child) {
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white24,
                  width: 2,
                ),
              ),
              child: Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Wave indicator
            ValueListenableBuilder<({int waveNumber, bool isFlashing})>(
              valueListenable: game.waveState,
              builder: (context, state, _) {
                return WaveIndicatorWidget(
                  waveNumber: state.waveNumber,
                  isFlashing: state.isFlashing,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
