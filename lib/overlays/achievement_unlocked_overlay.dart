import 'dart:async';
import 'dart:math';

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

class _AchievementUnlockedOverlayState
    extends State<AchievementUnlockedOverlay>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    Future.delayed(_totalDuration, () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _randomVictoryText() {
    const texts = [
      "YOU DID IT!",
      "VICTORY!",
      "SKILL RECOGNIZED",
      "CHAOS SURVIVED",
      "HARD EARNED",
      "LEGENDARY MOMENT",
    ];

    return texts[Random().nextInt(texts.length)];
  }

  @override
  Widget build(BuildContext context) {
    final achievementId = widget.unlockedAchievementIds.first;
    final remaining = widget.unlockedAchievementIds.length - 1;

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF191A22),
                    Color(0xFF0F1016),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFF6AA8FF).withValues(alpha: 0.5),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Victory Text
                  Text(
                    _randomVictoryText(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Icon Circle
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6AA8FF).withValues(alpha: 0.12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x336AA8FF),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 48,
                      color: Color(0xFF9BC5FF),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    formatAchievementId(achievementId),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Achievement Unlocked",
                    style: TextStyle(
                      color: Color(0xFF7A8397),
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),

                  if (remaining > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      "+ $remaining more unlocked",
                      style: const TextStyle(
                        color: Color(0xFF6AA8FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}