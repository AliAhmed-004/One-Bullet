import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/play_games_service.dart';
import 'package:one_bullet/services/settings_service.dart';
import 'package:one_bullet/theme/heat_theme.dart';

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

  final double _heat = 0.25;

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
      color: HeatTheme.background(_heat),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(child: _buildPanel()),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // color: HeatTheme.surface(_heat),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HeatTheme.accent(_heat).withValues(alpha: 0.35),
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: HeatTheme.accent(_heat).withValues(alpha: 0.15),
        //     blurRadius: 24,
        //     spreadRadius: 2,
        //   ),
        // ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== TITLE =====
          Text(
            'SYSTEM SETTINGS',
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: HeatTheme.textPrimary(_heat),
            ),
          ),

          const SizedBox(height: 24),

          // ===== TOGGLES =====
          _settingToggle(
            title: "Sound",
            valueListenable: SettingsService.soundEnabled,
            onChanged: SettingsService.setSound,
          ),

          const SizedBox(height: 14),

          _settingToggle(
            title: "Haptics",
            valueListenable: SettingsService.hapticsEnabled,
            onChanged: SettingsService.setHaptics,
          ),

          const SizedBox(height: 22),

          // ===== PLAY GAMES =====
          if (!PlayGamesService.instance.isSignedIn)
            _systemButton(
              label: "Sign in to Play Games",
              onTap: _signInToPlayGames,
            ),

          const SizedBox(height: 10),

          // ===== CLOSE =====
          _systemButton(label: "Close", accent: true, onTap: _close),
        ],
      ),
    );
  }

  Widget _settingToggle({
    required String title,
    required ValueListenable<bool> valueListenable,
    required ValueChanged<bool> onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueListenable,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: HeatTheme.surfaceGlow(_heat).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HeatTheme.accent(_heat).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: HeatTheme.textPrimary(_heat),
                    fontSize: 15,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: HeatTheme.accent(_heat),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _systemButton({
    required String label,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent
              ? HeatTheme.accent(_heat).withValues(alpha: 0.12)
              : HeatTheme.surfaceGlow(_heat).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: HeatTheme.accent(
              _heat,
            ).withValues(alpha: accent ? 0.4 : 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: accent
                  ? HeatTheme.accent(_heat)
                  : HeatTheme.textPrimary(_heat),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  void _signInToPlayGames() async {
    log("[SETTINGS] Signing into Play Games...");
    final success = await PlayGamesService.instance.signIn();

    log(success ? "[SETTINGS] Sign-in success" : "[SETTINGS] Sign-in failed");
  }
}
