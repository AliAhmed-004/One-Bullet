import 'package:flutter/material.dart';
import 'package:one_bullet/overlays/achievement_overlay_helpers.dart';

class AchievementUnlockedOverlay extends StatefulWidget {
  const AchievementUnlockedOverlay({
    required this.unlockedAchievementIds,
    required this.onDismissed,
    super.key,
  });

  final List<String> unlockedAchievementIds;
  final VoidCallback onDismissed;

  @override
  State<AchievementUnlockedOverlay> createState() =>
      _AchievementUnlockedOverlayState();
}

class _AchievementUnlockedOverlayState extends State<AchievementUnlockedOverlay>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 1400);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _totalDuration);
    _controller.forward();

    Future<void>.delayed(_totalDuration, () {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.unlockedAchievementIds;

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < ids.length; i++) ...[
                  _AchievementItem(
                    id: ids[i],
                    controller: _controller,
                    index: i,
                    count: ids.length,
                  ),
                  if (i != ids.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  const _AchievementItem({
    required this.id,
    required this.controller,
    required this.index,
    required this.count,
  });

  final String id;
  final AnimationController controller;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final end = (start + 0.32).clamp(0.0, 1.0);

    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final fade = Tween<double>(begin: 0, end: 1).animate(curve);
    final scale = Tween<double>(begin: 0.9, end: 1).animate(curve);

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF191A22), Color(0xFF101116)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF6AA8FF).withValues(alpha: 0.45)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33288CFF),
                blurRadius: 20,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF6AA8FF).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF9BC5FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Achievement Unlocked',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9BA3B5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatAchievementId(id),
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 1)
                Text(
                  '${index + 1}/$count',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8397),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
