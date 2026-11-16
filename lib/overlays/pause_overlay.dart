import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/theme/west.dart';
import 'package:one_bullet/theme/west_widgets.dart';

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
      color: West.dustDeep.withValues(alpha: 0.78),
      child: SafeArea(
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
    );
  }

  Widget _poster({required Widget child}) {
    return WantedPoster(
      key: ValueKey(_showConfirmation),
      width: 330,
      tilt: -0.015,
      seed: _showConfirmation ? 7 : 3,
      child: child,
    );
  }

  Widget _buildMenu() {
    return _poster(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HOLD UP',
            style: westTitle(size: 34, color: West.ink, spacing: 3),
          ),
          const SizedBox(height: 2),
          Text(
            'GAME PAUSED',
            style: westText(size: 12, color: West.rust, spacing: 4),
          ),
          const SizedBox(height: 22),
          WestButton(
            label: 'RESUME',
            icon: Icons.play_arrow,
            onPaper: true,
            primary: true,
            onTap: widget.game.resumeGame,
          ),
          WestButton(
            label: 'SETTINGS',
            icon: Icons.settings,
            onPaper: true,
            onTap: widget.game.openSettings,
          ),
          WestButton(
            label: 'EXIT TO MENU',
            icon: Icons.home,
            onPaper: true,
            onTap: _switchToConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm() {
    return _poster(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: West.blood, size: 46),
          const SizedBox(height: 12),
          Text(
            'LEAVE TOWN?',
            style: westTitle(size: 28, color: West.ink, spacing: 2),
          ),
          const SizedBox(height: 10),
          Text(
            'This run ends right here.',
            textAlign: TextAlign.center,
            style: westText(size: 13, color: West.ink, spacing: 0.8),
          ),
          const SizedBox(height: 20),
          WestButton(
            label: 'LEAVE RUN',
            icon: Icons.home,
            onPaper: true,
            primary: true,
            onTap: widget.game.returnToMenu,
          ),
          WestButton(
            label: 'STAY',
            icon: Icons.arrow_back,
            onPaper: true,
            onTap: _switchToMenu,
          ),
        ],
      ),
    );
  }
}
