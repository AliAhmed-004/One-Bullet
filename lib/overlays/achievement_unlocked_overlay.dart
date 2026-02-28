import 'dart:async';

import 'package:flutter/material.dart';
import 'package:one_bullet/overlays/achievement_overlay_helpers.dart';
import 'package:one_bullet/services/achievement_service.dart';

class AchievementUnlockedOverlay extends StatefulWidget {
  const AchievementUnlockedOverlay({
    required this.achievements,
    required this.onDismissed,
    super.key,
  });

  final List<Achievement> achievements;
  final VoidCallback onDismissed;

  @override
  State<AchievementUnlockedOverlay> createState() =>
      _AchievementUnlockedOverlayState();
}

class _AchievementUnlockedOverlayState extends State<AchievementUnlockedOverlay>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 1500);
  static const _displayDuration = Duration(seconds: 3);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _totalDuration);

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(_displayDuration, () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievements = widget.achievements;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 16),

                  // Victory Text
                  Text(
                    "ACHIEVEMENTS UNLOCKED: ${achievements.length}",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),

                  // SHow all the achievements in a list
                  if (achievements.length > 1) ...[
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: achievements.map((achievement) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                achievement.icon,
                                size: 22,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  achievement.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
