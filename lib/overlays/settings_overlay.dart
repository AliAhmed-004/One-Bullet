import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/settings_service.dart';
import 'package:one_bullet/theme/neon.dart';
import 'package:one_bullet/theme/neon_widgets.dart';

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

  static const double _heat = 0.25;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _scale = Tween(
      begin: 0.96,
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
      color: Neon.voidDeep,
      child: NeonBackdrop(
        heat: _heat,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: SingleChildScrollView(child: _buildPanel()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return NeonPanel(
      width: 340,
      color: Neon.violet,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== TITLE =====
          Text(
            'SETTINGS',
            style: neonDisplay(
              size: 22,
              spacing: 4,
              color: Colors.white,
              glow: Neon.cyan,
            ),
          ),

          const SizedBox(height: 24),

          // ===== TOGGLES =====
          _settingToggle(
            title: "SOUND",
            icon: Icons.volume_up_rounded,
            color: Neon.cyan,
            valueListenable: SettingsService.soundEnabled,
            onChanged: SettingsService.setSound,
          ),

          const SizedBox(height: 12),

          _settingToggle(
            title: "HAPTICS",
            icon: Icons.vibration,
            color: Neon.magenta,
            valueListenable: SettingsService.hapticsEnabled,
            onChanged: SettingsService.setHaptics,
          ),

          const SizedBox(height: 18),

          // ===== PLAY GAMES =====
          if (PlayGamesService.isSupportedPlatform) _playGamesSection(),

          const SizedBox(height: 8),

          // ===== CLOSE =====
          NeonButton(
            label: 'CLOSE',
            icon: Icons.close_rounded,
            primary: true,
            color: Neon.cyan,
            width: double.infinity,
            onTap: _close,
          ),
        ],
      ),
    );
  }

  Widget _playGamesSection() {
    final isSignedIn = PlayGamesService.instance.isSignedIn;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Neon.violet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Neon.violet.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 18,
                color: isSignedIn ? Neon.gold : Neon.violet,
              ),
              const SizedBox(width: 8),
              Text(
                'PLAY GAMES',
                style: neonDisplay(
                  size: 13,
                  weight: FontWeight.w700,
                  spacing: 2,
                  color: Neon.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSignedIn
                ? 'Connected. Achievements and leaderboards are active.'
                : 'Not connected. Sign in to save achievements and join leaderboards.',
            style: const TextStyle(
              color: Neon.textMuted,
              fontSize: 12,
              height: 1.35,
              decoration: TextDecoration.none,
            ),
          ),
          if (!isSignedIn) ...[
            const SizedBox(height: 8),
            NeonButton(
              label: 'CONNECT',
              color: Neon.violet,
              width: double.infinity,
              onTap: _signInToPlayGames,
            ),
          ],
        ],
      ),
    );
  }

  Widget _settingToggle({
    required String title,
    required IconData icon,
    required Color color,
    required ValueListenable<bool> valueListenable,
    required ValueChanged<bool> onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueListenable,
      builder: (context, value, _) {
        final c = value ? color : Neon.textMuted;

        return GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: value ? 0.8 : 0.3)),
              boxShadow: value
                  ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12)]
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: c, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: neonDisplay(
                      size: 14,
                      weight: FontWeight.w700,
                      spacing: 2,
                      color: value ? Colors.white : Neon.textMuted,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: color,
                  activeTrackColor: color.withValues(alpha: 0.35),
                  inactiveThumbColor: Neon.textMuted,
                  inactiveTrackColor: Neon.voidDeep,
                  trackOutlineColor: WidgetStatePropertyAll(
                    c.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _signInToPlayGames() async {
    log("[SETTINGS] Signing into Play Games...");
    final success = await PlayGamesService.instance.signIn();

    log(success ? "[SETTINGS] Sign-in success" : "[SETTINGS] Sign-in failed");
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Play Games connected successfully.'
              : 'Play Games sign-in failed. Please try again.',
        ),
      ),
    );

    setState(() {});
  }
}
