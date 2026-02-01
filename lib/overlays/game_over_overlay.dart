import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';

/// Overlay displayed when the player dies.
/// Shows "You Died!" text and a restart button.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    required this.game,
    super.key,
  });

  final OneBulletGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red,
              width: 3,
            ),
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
                  shadows: [
                    Shadow(
                      color: Colors.redAccent,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Restart button
              ElevatedButton(
                onPressed: () {
                  game.restart();
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
