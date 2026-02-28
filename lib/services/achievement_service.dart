import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// ===============================
/// ACHIEVEMENT DEFINITIONS
/// ===============================

/// Base class for all achievements.
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

/// Survival time-based achievement.
class TimeAchievement extends Achievement {
  final int requiredSeconds;

  const TimeAchievement({
    required super.id,
    required super.title,
    required super.icon,
    required this.requiredSeconds,
  });
}

/// Survival milestone achievements.
const List<TimeAchievement> kSurvivalAchievements = [
  TimeAchievement(
    id: 'survive_60',
    title: 'One Minute Survivor',
    icon: Icons.timer_outlined,
    requiredSeconds: 60,
  ),
  TimeAchievement(
    id: 'reach_endurance',
    title: 'Endurance Initiate',
    icon: Icons.hourglass_bottom,
    requiredSeconds: 90,
  ),
  TimeAchievement(
    id: 'survive_150',
    title: 'Relentless',
    icon: Icons.local_fire_department_outlined,
    requiredSeconds: 150,
  ),
  TimeAchievement(
    id: 'survive_240',
    title: 'Unbreakable Focus',
    icon: Icons.visibility_outlined,
    requiredSeconds: 240,
  ),
  TimeAchievement(
    id: 'survive_360',
    title: 'Iron Reflex',
    icon: Icons.flash_on_outlined,
    requiredSeconds: 360,
  ),
  TimeAchievement(
    id: 'survive_480',
    title: 'Bullet Master',
    icon: Icons.adjust,
    requiredSeconds: 480,
  ),
];

/// Master registry of all achievements (expandable later).
const List<Achievement> kAllAchievements = [
  ...kSurvivalAchievements,
];

/// ===============================
/// ACHIEVEMENT SERVICE
/// ===============================

class AchievementService {
  AchievementService._internal();
  static final AchievementService instance = AchievementService._internal();
  factory AchievementService() => instance;

  static const String _boxName = 'achievements';
  static const String _unlockedKey = 'unlocked';

  late final Box _box;

  /// In-memory unlocked cache.
  final Set<String> _unlockedCache = {};

  /// Lookup map for quick access.
  late final Map<String, Achievement> _achievementMap;

  /// Sorted survival achievements (category-specific logic).
  late final List<TimeAchievement> _timeAchievements;

  int get unlockedCount => _unlockedCache.length;

  /// ===============================
  /// INIT
  /// ===============================

  Future<void> init() async {
    log("[ACHIEVEMENT SERVICE] Initializing...");

    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }

    final stored = _box.get(_unlockedKey);
    if (stored is List) {
      _unlockedCache
        ..clear()
        ..addAll(stored.cast<String>());
    }

    log('[ACHIEVEMENT SERVICE] Cached unlocked: $_unlockedCache');

    // Build master map
    _achievementMap = {
      for (final a in kAllAchievements) a.id: a,
    };

    // Prepare sorted time achievements
    _timeAchievements = kSurvivalAchievements.toList()
      ..sort((a, b) => a.requiredSeconds.compareTo(b.requiredSeconds));
  }

  /// ===============================
  /// CORE GETTERS
  /// ===============================

  Set<String> getUnlockedIds() => Set.unmodifiable(_unlockedCache);

  Achievement? getAchievementById(String id) => _achievementMap[id];

  List<Achievement> getAllAchievements() =>
      List.unmodifiable(kAllAchievements);

  /// ===============================
  /// SURVIVAL TIME CHECK
  /// ===============================

  /// Returns newly unlocked Achievement objects.
  Future<List<Achievement>> checkAndUnlockForSurvivalTime(
    int seconds,
  ) async {
    log(
      "[ACHIEVEMENT SERVICE] Checking survival time: $seconds seconds",
    );

    final newlyUnlocked = <Achievement>[];

    for (final achievement in _timeAchievements) {
      if (seconds >= achievement.requiredSeconds &&
          !_unlockedCache.contains(achievement.id)) {
        newlyUnlocked.add(achievement);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _unlockedCache.addAll(newlyUnlocked.map((a) => a.id));
      await _box.put(_unlockedKey, _unlockedCache.toList());
    }

    log(
      "[ACHIEVEMENT SERVICE] Newly unlocked: ${newlyUnlocked.map((a) => a.id).toList()}",
    );

    return newlyUnlocked;
  }

  /// Returns next locked survival achievement.
  TimeAchievement? getNextLockedTimeAchievement() {
    for (final achievement in _timeAchievements) {
      if (!_unlockedCache.contains(achievement.id)) {
        return achievement;
      }
    }
    return null;
  }

  bool isUnlocked(String id) => _unlockedCache.contains(id);

  /// ===============================
  /// DEBUG / RESET
  /// ===============================

  Future<void> resetAll() async {
    _unlockedCache.clear();
    await _box.put(_unlockedKey, <String>[]);
  }
}