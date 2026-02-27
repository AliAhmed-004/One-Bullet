import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/overlays/achievement_overlay_helpers.dart';
import 'package:one_bullet/services/achievement_service.dart';

class AchievementsOverlay extends StatefulWidget {
  final OneBulletGame game;
  final bool returnToSettings;

  const AchievementsOverlay({
    super.key,
    required this.game,
    this.returnToSettings = false,
  });

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
    await _controller.reverse();
    widget.game.overlays.remove(OneBulletGame.achievementsOverlayId);
    if (widget.returnToSettings) {
      widget.game.overlays.add(OneBulletGame.settingsOverlayId);
    } else {
      widget.game.overlays.add(OneBulletGame.startScreenOverlayId);
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
    final all = AchievementService.instance.getAllAchievements();

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Container(
            width: 360,
            height: 520,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF0F0F12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ACHIEVEMENTS',
                        style: TextStyle(
                          color: Colors.white,
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
                          color: Colors.white10,
                        ),
                        child: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: all.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final ach = all[index];
                      final unlocked = AchievementService.instance.isUnlocked(
                        ach.id,
                      );

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
                                ? const Color(
                                    0xFF6AA8FF,
                                  ).withValues(alpha: 0.12)
                                : Colors.white10,
                          ),
                          child: Icon(
                            unlocked ? Icons.workspace_premium : Icons.lock,
                            color: unlocked
                                ? const Color(0xFF9BC5FF)
                                : Colors.white54,
                          ),
                        ),
                        title: Text(
                          formatAchievementId(ach.id),
                          style: TextStyle(
                            color: unlocked ? Colors.white : Colors.white70,
                            fontWeight: unlocked
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Survive ${_formatTime(ach.requiredSeconds)}',
                          style: const TextStyle(color: Color(0xFF8D94A8)),
                        ),
                        trailing: unlocked
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF6AA8FF),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Unlocked: ${AchievementService.instance.unlockedCount}/${all.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
