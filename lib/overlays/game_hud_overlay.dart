import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';

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
        );
      },
    );
  }
}
