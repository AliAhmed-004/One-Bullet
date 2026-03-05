import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:one_bullet/services/play_games_service.dart';

/// ===============================
/// ACHIEVEMENT DEFINITIONS
/// ===============================

abstract class Achievement {
  final String id;
  final String title;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class TimeAchievement extends Achievement {
  final int requiredSeconds;

  const TimeAchievement({
    required super.id,
    required super.title,
    required super.icon,
    required this.requiredSeconds,
  });
}

/// ===============================
/// ACHIEVEMENT LIST
/// ===============================

const List<TimeAchievement> kSurvivalAchievements = [
  if (kDebugMode)
    TimeAchievement(
      id: 'debug_10_seconds',
      title: '10 Seconds Survivor (Debug)',
      icon: Icons.bug_report_outlined,
      requiredSeconds: 10,
    ),
  TimeAchievement(
    id: 'CgkIvLXzppUPEAIQAQ',
    title: 'First Steps',
    icon: Icons.timer_outlined,
    requiredSeconds: 60,
  ),
  TimeAchievement(
    id: 'CgkIvLXzppUPEAIQAg',
    title: 'Endurance Initiate',
    icon: Icons.hourglass_bottom,
    requiredSeconds: 90,
  ),
  TimeAchievement(
    id: 'CgkIvLXzppUPEAIQAw',
    title: 'Relentless',
    icon: Icons.local_fire_department_outlined,
    requiredSeconds: 150,
  ),
  TimeAchievement(
    id: 'CgkIvLXzppUPEAIQBA',
    title: 'Unbreakable Focus',
    icon: Icons.visibility_outlined,
    requiredSeconds: 240,
  ),
  TimeAchievement(
    id: 'CgkIvLXzppUPEAIQBQ',
    title: 'Iron Reflex',
    icon: Icons.flash_on_outlined,
    requiredSeconds: 360,
  ),
  TimeAchievement(
    id: 'CgkIvLXzppUPEAIQBg',
    title: 'Bullet Master',
    icon: Icons.adjust,
    requiredSeconds: 480,
  ),
];

const List<Achievement> kAllAchievements = [...kSurvivalAchievements];

/// ===============================
/// ACHIEVEMENT SERVICE
/// ===============================

class AchievementService {
  AchievementService._internal();
  static final AchievementService instance = AchievementService._internal();
  factory AchievementService() => instance;

  late final List<TimeAchievement> _timeAchievements;

  /// Debug-only in-memory session cache
  /// prevents duplicate popups during one run
  final Set<String> _sessionUnlocked = {};

  /// ===============================
  /// INIT
  /// ===============================

  Future<void> init() async {
    print('[ACHIEVEMENT SERVICE] Initializing');

    _timeAchievements = kSurvivalAchievements.toList()
      ..sort((a, b) => a.requiredSeconds.compareTo(b.requiredSeconds));
  }

  /// ===============================
  /// SURVIVAL CHECK
  /// ===============================

  Future<List<Achievement>> checkAndUnlockForSurvivalTime(int seconds) async {
    print('[ACHIEVEMENT SERVICE] Checking survival time: $seconds');

    final unlocked = <Achievement>[];

    for (final achievement in _timeAchievements) {
      if (seconds >= achievement.requiredSeconds &&
          !_sessionUnlocked.contains(achievement.id)) {
        unlocked.add(achievement);
      }
    }

    if (unlocked.isEmpty) return [];

    _sessionUnlocked.addAll(unlocked.map((a) => a.id));

    if (!PlayGamesService.instance.isSignedIn) {
      print('[ACHIEVEMENT SERVICE] Play Games not signed in');
      return unlocked;
    }

    for (final achievement in unlocked) {
      if (achievement.id.startsWith('debug_')) continue;

      try {
        final gsAchievement = gs.Achievement(
          androidID: achievement.id,
          iOSID: achievement.id,
          percentComplete: 100,
          showsCompletionBanner: true,
        );

        await gs.Achievements.unlock(achievement: gsAchievement);

        print(
          '[ACHIEVEMENT SERVICE] Play Games unlock sent: ${achievement.id}',
        );
      } catch (e) {
        print(
          '[ACHIEVEMENT SERVICE] Play Games unlock failed: ${achievement.id}',
        );
      }
    }

    return unlocked;
  }

  /// ===============================
  /// NEXT TARGET (UI hint)
  /// ===============================

  TimeAchievement? getNextTarget(int seconds) {
    for (final achievement in _timeAchievements) {
      if (seconds < achievement.requiredSeconds) {
        return achievement;
      }
    }
    return null;
  }
}
