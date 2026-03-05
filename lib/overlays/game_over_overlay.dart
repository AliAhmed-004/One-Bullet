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

  @override
  void initState() {
    super.initState();

    // Get contextual death message based on survival time
    final survivalSeconds = widget.game.survivalTime.value.inSeconds;
    _deathMessage = DeathMessageService.instance.getDeathMessage(
      survivalSeconds,
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

    final accent = isNewRecord ? Colors.amberAccent : Colors.redAccent;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          const SizedBox.expand(),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: _buildCard(
                  accent: accent,
                  finalTime: finalTime,
                  isNewRecord: isNewRecord,
                  canContinue: canContinue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Color accent,
    required Duration finalTime,
    required bool isNewRecord,
    required bool canContinue,
  }) {
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GAME OVER',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Theme.of(context).colorScheme.errorContainer,
            ),
          ),
          const SizedBox(height: 12),

          // Death message - contextual based on achievement proximity
          _buildDeathMessage(),

          const SizedBox(height: 20),

          Text(
            'Time Survived',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.5,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ScoreService.formatDuration(finalTime),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 3,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Next achievement progress indicator
          if (_deathMessage.secondsToNextAchievement != null) ...[
            const SizedBox(height: 16),
            _buildNextAchievementSection(),
          ],

          if (isNewRecord) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.6),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amberAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'NEW HIGH SCORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 36),

          if (canContinue) ...[
            _isLoadingAd
                ? const SizedBox(
                    height: 52,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _ActionButton(
                    label: 'Continue (Watch Ad)',
                    icon: Icons.play_circle_fill,
                    accentColor: Colors.greenAccent,
                    onTap: _onContinuePressed,
                  ),
            const SizedBox(height: 16),
          ],

          _ActionButton(
            label: 'Restart',
            icon: Icons.refresh,
            accentColor: Theme.of(context).colorScheme.errorContainer,
            onTap: widget.game.restart,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Main Menu',
            icon: Icons.home,
            accentColor: Theme.of(context).colorScheme.primary,
            onTap: widget.game.returnToMenu,
          ),
        ],
      ),
    );
  }

  /// Builds the contextual death message widget.
  Widget _buildDeathMessage() {
    final Color messageColor;
    final IconData? icon;

    switch (_deathMessage.type) {
      case DeathMessageType.nearMiss:
        // Infuriating red/orange - you were SO close
        messageColor = Colors.deepOrangeAccent;
        icon = Icons.local_fire_department;
      case DeathMessageType.almostThere:
        // Encouraging amber - keep trying
        messageColor = Colors.amberAccent;
        icon = Icons.trending_up;
      case DeathMessageType.sarcastic:
        // Playful blue/gray - lighthearted
        messageColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        icon = null;
      case DeathMessageType.champion:
        // Respectful gold - you've earned it
        messageColor = Colors.amber;
        icon = Icons.workspace_premium;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Main message
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: messageColor, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  _deathMessage.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: messageColor,
                    fontWeight: _deathMessage.type == DeathMessageType.nearMiss
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the "Next Achievement" progress section.
  Widget _buildNextAchievementSection() {
    final secondsLeft = _deathMessage.secondsToNextAchievement!;
    final achievementTitle = _deathMessage.nextAchievementTitle!;
    final survivalSeconds = widget.game.survivalTime.value.inSeconds;

    // Find the achievement's required seconds from the service
    final requiredSeconds = secondsLeft + survivalSeconds;

    // Calculate progress percentage
    final progress = (survivalSeconds / requiredSeconds).clamp(0.0, 1.0);

    // Color based on proximity
    final Color accentColor;
    final String proximityText;

    if (secondsLeft <= 10) {
      accentColor = Colors.deepOrangeAccent;
      proximityText = 'SO CLOSE!';
    } else if (secondsLeft <= 20) {
      accentColor = Colors.amberAccent;
      proximityText = 'Almost there!';
    } else {
      accentColor = Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.7);
      proximityText = 'Next target';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                proximityText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: accentColor,
                ),
              ),
              Text(
                '${secondsLeft}s to go',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Achievement name
          Text(
            achievementTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 4),

          // Progress text
          Text(
            '${survivalSeconds}s / ${requiredSeconds}s',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _onContinuePressed() {
    setState(() => _isLoadingAd = true);

    AdService.showRewardedAd(
      onRewardEarned: () {
        widget.game.continueGame();
      },
      onAdDismissedWithoutReward: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
        }
      },
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.accentColor.withValues(alpha: 0.12);
    final borderColor = widget.accentColor.withValues(alpha: 0.5);

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
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
