import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/death_message_service.dart';
import 'package:one_bullet/services/score_service.dart';

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({required this.game, super.key});

  final OneBulletGame game;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  bool _isLoadingAd = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final DeathMessageResult _deathMessage;

  static const _ember = Color(0xFFFF6A3D);
  static const _gold = Color(0xFFFFC46B);
  static const _deepHeat = Color(0xFFB83A1B);

  @override
  void initState() {
    super.initState();

    final seconds = widget.game.survivalTime.value.inSeconds;

    _deathMessage = DeathMessageService.instance.getDeathMessage(seconds);

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

  @override
  Widget build(BuildContext context) {
    final finalTime = widget.game.survivalTime.value;
    final isNewRecord = widget.game.isNewHighScore;
    final canContinue = widget.game.canContinue;

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: _buildCard(finalTime, isNewRecord, canContinue),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Duration finalTime, bool isNewRecord, bool canContinue) {
    return Container(
      width: 370,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B120D), Color(0xFF120D09)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isNewRecord ? _gold : _ember).withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 2,
            color: _ember.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GAME OVER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: isNewRecord ? _gold : _ember,
            ),
          ),

          const SizedBox(height: 12),

          _buildDeathMessage(),

          const SizedBox(height: 22),

          Text(
            'TIME SURVIVED',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.8,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            ScoreService.formatDuration(finalTime),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),

          if (_deathMessage.secondsToNextAchievement != null) ...[
            const SizedBox(height: 20),
            _buildNextAchievementSection(),
          ],

          if (isNewRecord) ...[const SizedBox(height: 18), _buildRecordBadge()],

          const SizedBox(height: 30),

          if (canContinue) ...[
            _isLoadingAd
                ? const SizedBox(
                    height: 52,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : _ActionButton(
                    label: 'Continue',
                    icon: Icons.play_circle_fill,
                    accentColor: _gold,
                    onTap: _onContinuePressed,
                  ),
            const SizedBox(height: 14),
          ],

          _ActionButton(
            label: 'Restart',
            icon: Icons.refresh,
            accentColor: _ember,
            onTap: widget.game.restart,
          ),

          const SizedBox(height: 12),

          _ActionButton(
            label: 'Main Menu',
            icon: Icons.home,
            accentColor: _deepHeat,
            onTap: widget.game.returnToMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: _gold, size: 16),
          SizedBox(width: 8),
          Text(
            'NEW RECORD',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeathMessage() {
    return Text(
      _deathMessage.message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: _gold.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildNextAchievementSection() {
    final left = _deathMessage.secondsToNextAchievement!;
    final title = _deathMessage.nextAchievementTitle!;
    final survived = widget.game.survivalTime.value.inSeconds;
    final target = survived + left;

    final progress = (survived / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ember.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ember.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(_ember),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$survived s / $target s',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  void _onContinuePressed() {
    setState(() => _isLoadingAd = true);

    AdService.showRewardedAd(
      onRewardEarned: widget.game.continueGame,
      onAdDismissedWithoutReward: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
        }
      },
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
