import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/ad_service.dart';
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
  /// Whether the rewarded ad is currently loading/showing.
  bool _isLoadingAd = false;

  @override
  Widget build(BuildContext context) {
    // Get the final survival time
    final finalTime = widget.game.survivalTime.value;
    final isNewRecord = widget.game.isNewHighScore;
    final canContinue = widget.game.canContinue;

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

              // Continue button (watch ad to revive)
              if (canContinue) ...[
                _isLoadingAd
                    ? const SizedBox(
                        height: 56,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _onContinuePressed,
                        icon: const Icon(Icons.play_circle_fill, size: 24),
                        label: const Text(
                          'Watch Ad to Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
              ],

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

  /// Called when the user taps "Watch Ad to Continue".
  void _onContinuePressed() {
    setState(() {
      _isLoadingAd = true;
    });

    AdService.showRewardedAd(
      onRewardEarned: () {
        // User watched full ad AND ad is now closed - continue the game
        debugPrint('GameOverOverlay: onRewardEarned callback - calling continueGame()');
        widget.game.continueGame();
      },
      onAdDismissedWithoutReward: () {
        // User skipped or ad failed - reset loading state
        debugPrint('GameOverOverlay: onAdDismissedWithoutReward callback');
        if (mounted) {
          setState(() {
            _isLoadingAd = false;
          });
        }
      },
    );
  }
}
