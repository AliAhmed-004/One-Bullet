import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/settings_service.dart';

class SettingsOverlay extends StatelessWidget {
  final OneBulletGame game;
  const SettingsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              /// SOUND SWITCH
              ValueListenableBuilder<bool>(
                valueListenable: SettingsService.soundEnabled,
                builder: (context, value, _) {
                  return _buildSettingsRow(
                    title: "Sound Effects",
                    value: value,
                    onChanged: SettingsService.setSound,
                  );
                },
              ),

              const SizedBox(height: 20),

              /// HAPTICS SWITCH
              ValueListenableBuilder<bool>(
                valueListenable: SettingsService.hapticsEnabled,
                builder: (context, value, _) {
                  return _buildSettingsRow(
                    title: "Haptic Feedback",
                    value: value,
                    onChanged: SettingsService.setHaptics,
                  );
                },
              ),

              const SizedBox(height: 40),

              // CLOSE BUTTON
              GestureDetector(
                onTap: () {
                  game.closeSettings();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
