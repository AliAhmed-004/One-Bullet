import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';

/// Overlay displayed when the game is paused.
/// Shows pause menu with resume and back to menu options.
class PauseOverlay extends StatefulWidget {
  const PauseOverlay({
    required this.game,
    super.key,
  });

  final OneBulletGame game;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  bool _showConfirmation = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Center(
          child: _showConfirmation
              ? _buildConfirmationDialog()
              : _buildPauseMenu(),
        ),
      ),
    );
  }

  Widget _buildPauseMenu() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white24,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Game Paused" title
          const Text(
            'Game Paused',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),

          // Resume Game button
          _buildMenuButton(
            label: 'Resume Game',
            icon: Icons.play_arrow,
            color: Colors.green,
            onTap: () => widget.game.resumeGame(),
          ),
          const SizedBox(height: 16),

          // Settings button
          _buildMenuButton(
            label: 'Settings',
            icon: Icons.settings,
            color: Colors.blueGrey,
            onTap: () => widget.game.openSettings(),
          ),
          const SizedBox(height: 16),

          // Back to Menu button
          _buildMenuButton(
            label: 'Back to Menu',
            icon: Icons.home,
            color: Colors.orange,
            onTap: () => setState(() => _showConfirmation = true),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialog() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),

          // Confirmation text
          const Text(
            'Return to Menu?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your current progress will be lost.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Buttons row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cancel button
              _buildSmallButton(
                label: 'Cancel',
                color: Colors.grey,
                onTap: () => setState(() => _showConfirmation = false),
              ),
              const SizedBox(width: 16),

              // Confirm button
              _buildSmallButton(
                label: 'Confirm',
                color: Colors.orange,
                onTap: () => widget.game.returnToMenu(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
