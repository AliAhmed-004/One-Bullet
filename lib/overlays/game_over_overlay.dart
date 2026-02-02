import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/score_service.dart';

/// Overlay displayed when the player dies.
/// Shows "You Died!" text, final score, high score status, and action buttons.
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  @override
  Widget build(BuildContext context) {
    // Get the final survival time
    final finalTime = widget.game.survivalTime.value;
    final isNewRecord = widget.game.isNewHighScore;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNewRecord ? Colors.amber : Colors.red,
              width: 3,
            ),
            boxShadow: isNewRecord
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "You Died!" text
              const Text(
                'You Died!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  shadows: [Shadow(color: Colors.redAccent, blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 24),

              // Final score display
              Text(
                'Time Survived',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ScoreService.formatDuration(finalTime),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),

              // New high score indicator
              if (isNewRecord) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'NEW HIGH SCORE!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // TODO: Re-enable continue button when ads are implemented after Play Store publication
              // Continue button (watch ad to revive) - currently disabled
              // if (canContinue) ...[
              //   ElevatedButton.icon(
              //     onPressed: _onContinuePressed,
              //     icon: const Icon(Icons.play_circle_fill, size: 24),
              //     label: const Text('Watch Ad to Continue'),
              //     ...
              //   ),
              // ],

              // Restart button
              ElevatedButton(
                onPressed: () {
                  widget.game.restart();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Restart',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
