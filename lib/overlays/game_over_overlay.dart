import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/death_message_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/theme/west.dart';
import 'package:one_bullet/theme/west_widgets.dart';

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
      color: West.dustDeep.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildCard(finalTime, isNewRecord, canContinue),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Duration finalTime, bool isNewRecord, bool canContinue) {
    return WantedPoster(
      width: 350,
      tilt: -0.012,
      seed: 5,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DEAD',
            style: westTitle(size: 54, color: West.blood, spacing: 6),
          ),
          Text(
            'OR ALIVE? NOT ANYMORE',
            style: westText(size: 11, color: West.ink, spacing: 3),
          ),
          const SizedBox(height: 12),
          _buildDeathMessage(),
          const SizedBox(height: 20),
          Text(
            'TIME SURVIVED',
            style: westText(size: 11, color: West.rust, spacing: 3),
          ),
          const SizedBox(height: 4),
          Text(
            ScoreService.formatDuration(finalTime),
            style: westTitle(size: 44, color: West.ink, spacing: 3),
          ),
          if (_deathMessage.secondsToNextAchievement != null) ...[
            const SizedBox(height: 16),
            _buildNextAchievementSection(),
          ],
          if (isNewRecord) ...[const SizedBox(height: 16), _buildRecordBadge()],
          const SizedBox(height: 22),
          if (canContinue) ...[
            _isLoadingAd
                ? const SizedBox(
                    height: 52,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: West.ink,
                      ),
                    ),
                  )
                : WestButton(
                    label: 'CONTINUE',
                    icon: Icons.play_circle_fill,
                    onPaper: true,
                    primary: true,
                    onTap: _onContinuePressed,
                  ),
          ],
          WestButton(
            label: 'RESTART',
            icon: Icons.refresh,
            onPaper: true,
            primary: !canContinue,
            onTap: widget.game.restart,
          ),
          WestButton(
            label: 'MAIN MENU',
            icon: Icons.home,
            onPaper: true,
            onTap: widget.game.returnToMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordBadge() {
    // Rubber-stamp look: red ink, slightly rotated.
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: West.blood, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: West.blood, size: 18),
            const SizedBox(width: 8),
            Text(
              'NEW RECORD',
              style: westText(
                size: 14,
                color: West.blood,
                spacing: 2,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeathMessage() {
    return Text(
      _deathMessage.message,
      textAlign: TextAlign.center,
      style: westText(size: 14, color: West.ink, spacing: 0.6),
    );
  }

  Widget _buildNextAchievementSection() {
    final left = _deathMessage.secondsToNextAchievement!;
    final title = _deathMessage.nextAchievementTitle!;
    final survived = widget.game.survivalTime.value.inSeconds;
    final target = survived + left;

    final progress = (survived / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: West.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: West.ink.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: westText(size: 13, color: West.ink, spacing: 0.6),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: West.ink.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(West.rust),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$survived s / $target s',
            style: westText(size: 10, color: West.ink, spacing: 1),
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
