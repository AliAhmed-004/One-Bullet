import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';

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

  void _switchToConfirmation() {
    setState(() => _showConfirmation = true);
  }

  void _switchToMenu() {
    setState(() => _showConfirmation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showConfirmation
                        ? _buildConfirmationDialog()
                        : _buildPauseMenu(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      key: ValueKey(_showConfirmation),
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPauseMenu() {
    return _buildCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PAUSED',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          _AnimatedMenuButton(
            label: 'Resume Game',
            icon: Icons.play_arrow,
            accentColor: Colors.greenAccent,
            onTap: widget.game.resumeGame,
          ),
          const SizedBox(height: 16),

          _AnimatedMenuButton(
            label: 'Settings',
            icon: Icons.settings,
            accentColor: Colors.blueGrey,
            onTap: widget.game.openSettings,
          ),
          const SizedBox(height: 16),

          _AnimatedMenuButton(
            label: 'Back to Menu',
            icon: Icons.home,
            accentColor: Colors.orangeAccent,
            onTap: _switchToConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialog() {
    return _buildCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 48,
          ),
          const SizedBox(height: 20),
          const Text(
            'Return to Menu?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your current progress will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedMenuButton(
                label: 'Cancel',
                icon: Icons.close,
                accentColor: Colors.grey,
                small: true,
                onTap: _switchToMenu,
              ),
              const SizedBox(width: 14),
              _AnimatedMenuButton(
                label: 'Confirm',
                icon: Icons.check,
                accentColor: Colors.orangeAccent,
                small: true,
                onTap: widget.game.returnToMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedMenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool small;

  const _AnimatedMenuButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.small = false,
  });

  @override
  State<_AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<_AnimatedMenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.accentColor.withOpacity(0.12);
    final borderColor = widget.accentColor.withOpacity(0.4);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.small ? null : 240,
          padding: EdgeInsets.symmetric(
            horizontal: widget.small ? 20 : 24,
            vertical: widget.small ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.15),
                blurRadius: 18,
                spreadRadius: _pressed ? 0 : 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize:
                widget.small ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

