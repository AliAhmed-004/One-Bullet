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
      color: Colors.black.withValues(alpha: 0.72),
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
    return Container(
      key: ValueKey(_showConfirmation),
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF12161C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFB24A).withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B2F).withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMenu() {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "PAUSED",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFFFFC46B),
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
            color: Color(0xFFFF7A3C),
            size: 46,
          ),
          const SizedBox(height: 16),
          const Text(
            "Leave the run?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFC46B),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Everything currently in motion stops here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white60),
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

class _HeatButton extends StatefulWidget {
  const _HeatButton({
    required this.label,
    required this.icon,
    required this.heat,
    required this.onTap,
  });

  final String label;
  final IconData icon;

  /// 0.0 = calm, 1.0 = danger
  final double heat;

  final VoidCallback onTap;

  @override
  State<_HeatButton> createState() => _HeatButtonState();
}

class _HeatButtonState extends State<_HeatButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.heat.clamp(0.0, 1.0);

    // Base ember palette
    const cool = Color(0xFFFFC46B);
    const hot = Color(0xFFFF3B2F);

    final color = Color.lerp(cool, hot, t)!;

    final bg = color.withValues(alpha: 0.10 + (t * 0.08));
    final border = color.withValues(alpha: 0.25 + (t * 0.25));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.97 : 1,
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
