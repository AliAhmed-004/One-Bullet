import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/settings_service.dart';
import 'package:one_bullet/theme/west.dart';
import 'package:one_bullet/theme/west_widgets.dart';

/// Settings as a floating WANTED-poster dialog over a dimmed scene.
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
      color: West.dustDeep.withValues(alpha: 0.78),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return WantedPoster(
      width: 340,
      tilt: 0.012,
      seed: 11,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HOUSE RULES',
            style: westTitle(size: 28, color: West.ink, spacing: 2),
          ),
          const SizedBox(height: 2),
          Text(
            'SETTINGS',
            style: westText(size: 12, color: West.rust, spacing: 4),
          ),
          const SizedBox(height: 20),
          _settingToggle(
            title: 'SOUND',
            icon: Icons.volume_up_rounded,
            valueListenable: SettingsService.soundEnabled,
            onChanged: SettingsService.setSound,
          ),
          const SizedBox(height: 10),
          _settingToggle(
            title: 'HAPTICS',
            icon: Icons.vibration,
            valueListenable: SettingsService.hapticsEnabled,
            onChanged: SettingsService.setHaptics,
          ),
          const SizedBox(height: 16),
          if (PlayGamesService.isSupportedPlatform) _playGamesSection(),
          const SizedBox(height: 6),
          WestButton(
            label: 'CLOSE',
            icon: Icons.close_rounded,
            onPaper: true,
            primary: true,
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
        color: West.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: West.ink.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 18,
                color: isSignedIn ? West.rust : West.ink,
              ),
              const SizedBox(width: 8),
              Text(
                'PLAY GAMES',
                style: westText(
                  size: 13,
                  weight: FontWeight.w700,
                  spacing: 2,
                  color: West.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSignedIn
                ? 'Connected. Achievements and leaderboards are active.'
                : 'Not connected. Sign in to save achievements and join leaderboards.',
            style: westText(size: 12, color: West.ink, spacing: 0.4),
          ),
          if (!isSignedIn) ...[
            const SizedBox(height: 8),
            WestButton(
              label: 'CONNECT',
              onPaper: true,
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
    required ValueListenable<bool> valueListenable,
    required ValueChanged<bool> onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueListenable,
      builder: (context, value, _) {
        final c = value ? West.ink : West.ink.withValues(alpha: 0.45);

        return GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: West.ink.withValues(alpha: value ? 0.08 : 0.02),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c, width: value ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: c, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: westText(
                      size: 14,
                      weight: FontWeight.w700,
                      spacing: 2,
                      color: c,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: West.parchment,
                  activeTrackColor: West.rust,
                  inactiveThumbColor: West.parchmentDark,
                  inactiveTrackColor: West.ink.withValues(alpha: 0.25),
                  trackOutlineColor: WidgetStatePropertyAll(c),
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
