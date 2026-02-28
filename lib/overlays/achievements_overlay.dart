import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/achievement_service.dart';

class AchievementsOverlay extends StatefulWidget {
  final OneBulletGame? game;
  final bool returnToSettings;

  // 👇 Add these
  final List<Achievement>? previewAchievements;
  final Set<String>? previewUnlocked;

  const AchievementsOverlay({
    super.key,
    this.game,
    this.returnToSettings = false,
    this.previewAchievements,
    this.previewUnlocked,
  });

  bool get isPreview => previewAchievements != null;

  @override
  State<AchievementsOverlay> createState() => _AchievementsOverlayState();
}

class _AchievementsOverlayState extends State<AchievementsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() async {
    if (widget.isPreview) return;

    await _controller.reverse();
    widget.game!.overlays.remove(OneBulletGame.achievementsOverlayId);

    if (widget.returnToSettings) {
      widget.game!.overlays.add(OneBulletGame.settingsOverlayId);
    } else {
      widget.game!.overlays.add(OneBulletGame.startScreenOverlayId);
    }
  }

  String _formatTime(int seconds) {
    final d = Duration(seconds: seconds);
    final minutes = d.inMinutes;
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final all =
        widget.previewAchievements ??
        AchievementService.instance.getAllAchievements();

    final unlockedCount =
        widget.previewUnlocked?.length ??
        AchievementService.instance.unlockedCount;

    bool isUnlocked(String id) {
      if (widget.previewUnlocked != null) {
        return widget.previewUnlocked!.contains(id);
      }
      return AchievementService.instance.isUnlocked(id);
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Container(
            width: 360,
            height: 520,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceBright,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ACHIEVEMENTS',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: all.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final ach = all[index];
                      final unlocked = isUnlocked(ach.id);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: unlocked
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.06),
                          ),
                          child: Icon(
                            ach.icon,
                            color: unlocked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                          ),
                        ),
                        title: Text(
                          ach.title,
                          style: TextStyle(
                            color: unlocked
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            fontWeight: unlocked
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: _buildSubtitle(ach),
                        trailing: unlocked
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : Icon(
                                Icons.lock,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Unlocked: $unlockedCount/${all.length}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(Achievement ach) {
    if (ach is TimeAchievement) {
      return Text(
        'Survive for ${_formatTime(ach.requiredSeconds)}',
        style: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
