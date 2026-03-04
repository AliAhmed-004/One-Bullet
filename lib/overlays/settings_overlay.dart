import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/achievement_service.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/settings_service.dart';

class SettingsOverlay extends StatefulWidget {
  final OneBulletGame game;
  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _scale = Tween(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() async {
    await _controller.reverse();
    widget.game.closeSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          const SizedBox.expand(),

          /// Animated card
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(scale: _scale, child: _buildCard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 30),

          /// SOUND
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

          const SizedBox(height: 18),

          /// HAPTICS
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

          const SizedBox(height: 18),
          _AnimatedButton(
            label: "Sign in to Play Games",
            onTap: _signInToPlayGames,
          ),

          const SizedBox(height: 32),

          _AnimatedButton(label: "Close", onTap: _close),
          const SizedBox(height: 8),

          if (kDebugMode)
            _AnimatedButton(
              label: "Reset Achievements",
              onTap: _resetAchievements,
            ),
        ],
      ),
    );
  }

  void _resetAchievements() async {
    await AchievementService.instance.resetAll();
    log("[SETTINGS OVERLAY] Achievements have been reset.");
  }

  Widget _buildSettingsRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _signInToPlayGames() async {
    log("[SETTINGS OVERLAY] Attempting to sign in to Play Games...");
    final success = await PlayGamesService.instance.signIn();
    if (success) {
      log("[SETTINGS OVERLAY] User signed in to Play Games successfully.");
    } else {
      log("[SETTINGS OVERLAY] Failed to sign in to Play Games.");
    }
  }
}

class _AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedButton({required this.label, required this.onTap});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
