import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/theme/neon.dart';
import 'package:one_bullet/theme/neon_widgets.dart';

class PauseOverlay extends StatefulWidget {
  const PauseOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  bool _showConfirmation = false;

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

  void _switchToConfirmation() => setState(() => _showConfirmation = true);
  void _switchToMenu() => setState(() => _showConfirmation = false);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Neon.voidDeep.withValues(alpha: 0.82),
      child: Stack(
        children: [
          const SizedBox.expand(),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _showConfirmation ? _buildConfirm() : _buildMenu(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return NeonPanel(
      key: ValueKey(_showConfirmation),
      width: 340,
      child: child,
    );
  }

  Widget _buildMenu() {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "PAUSED",
            style: neonDisplay(
              size: 24,
              spacing: 4,
              color: Colors.white,
              glow: Neon.cyan,
            ),
          ),
          const SizedBox(height: 28),

          _HeatButton(
            label: "RESUME",
            icon: Icons.play_arrow,
            heat: 0.15,
            onTap: widget.game.resumeGame,
          ),

          _HeatButton(
            label: "SETTINGS",
            icon: Icons.settings,
            heat: 0.45,
            onTap: widget.game.openSettings,
          ),

          _HeatButton(
            label: "EXIT TO MENU",
            icon: Icons.home,
            heat: 0.85,
            onTap: _switchToConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm() {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Neon.orange,
            size: 46,
          ),
          const SizedBox(height: 16),
          Text(
            "LEAVE THE RUN?",
            style: neonDisplay(size: 18, color: Colors.white, glow: Neon.orange),
          ),
          const SizedBox(height: 10),
          const Text(
            "Everything currently in motion stops here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Neon.textMuted),
          ),
          const SizedBox(height: 22),

          _HeatButton(
            label: "LEAVE RUN",
            icon: Icons.home,
            heat: 0.85,
            onTap: widget.game.returnToMenu,
          ),
          _HeatButton(
            label: "STAY",
            icon: Icons.arrow_back,
            heat: 0.25,
            onTap: _switchToMenu,
          ),
        ],
      ),
    );
  }
}

class _HeatButton extends StatelessWidget {
  const _HeatButton({
    required this.label,
    required this.icon,
    required this.heat,
    required this.onTap,
  });

  final String label;
  final IconData icon;

  /// 0.0 = calm (cyan), 1.0 = danger (orange/magenta)
  final double heat;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeonButton(
      label: label,
      icon: icon,
      color: Neon.accent(heat),
      onTap: onTap,
    );
  }
}
