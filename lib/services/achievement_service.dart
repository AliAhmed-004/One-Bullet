import 'dart:developer';

import 'package:hive/hive.dart';

/// Represents a single achievement definition.
class TimeAchievement {
  final String id;
  final int requiredSeconds;

  const TimeAchievement({required this.id, required this.requiredSeconds});
}

/// List of all survival time-based achievements.
const List<TimeAchievement> kSurvivalAchievements = [
  TimeAchievement(id: 'survive_60', requiredSeconds: 60),
  TimeAchievement(id: 'reach_endurance', requiredSeconds: 90),
  TimeAchievement(id: 'survive_150', requiredSeconds: 150),
  TimeAchievement(id: 'survive_240', requiredSeconds: 240),
  TimeAchievement(id: 'survive_360', requiredSeconds: 360),
  TimeAchievement(id: 'survive_480', requiredSeconds: 480),
];

class AchievementService {
  /// Singleton pattern for global access.
  AchievementService._internal();
  static final AchievementService instance = AchievementService._internal();

  factory AchievementService() => instance;

  /// Hive box name and keys.
  static const String _boxName = 'achievements';
  static const String _unlockedKey = 'unlocked';

  late final Box _box;

  /// Cached unlocked achievements (in-memory for performance).
  final Set<String> _unlockedCache = {};

  /// Sorted list (defensive ordering).
  late final List<TimeAchievement> _sortedAchievements;

  /// Initialize Hive and cache unlocked achievements.
  Future<void> init() async {
    log("[ACHIEVEMENT SERVICE] Initializing AchievementService...");
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }

    // Cache unlocked achievements
    final stored = _box.get(_unlockedKey);
    if (stored is List) {
      _unlockedCache
        ..clear()
        ..addAll(stored.cast<String>());
    }

    log('[ACHIEVEMENT SERVICE] Cached unlocked: $_unlockedCache');

    // Defensive sort
    _sortedAchievements = List.of(kSurvivalAchievements)
      ..sort((a, b) => a.requiredSeconds.compareTo(b.requiredSeconds));
  }

  /// Returns all unlocked achievement IDs.
  Set<String> getUnlockedAchievements() {
    return Set.unmodifiable(_unlockedCache);
  }

  /// Checks and unlocks achievements based on survival time.
  /// Returns list of newly unlocked IDs.
  Future<List<String>> checkAndUnlockForSurvivalTime(int seconds) async {
    log("[ACHIEVEMENT SERVICE] Checking achievements for survival time: $seconds seconds");
    final newlyUnlocked = <String>[];

    for (final achievement in _sortedAchievements) {
      if (seconds >= achievement.requiredSeconds &&
          !_unlockedCache.contains(achievement.id)) {
        newlyUnlocked.add(achievement.id);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _unlockedCache.addAll(newlyUnlocked);
      await _box.put(_unlockedKey, _unlockedCache.toList());
    }

    log("[ACHIEVEMENT SERVICE] Newly unlocked achievements: $newlyUnlocked");

    return newlyUnlocked;
  }

  /// Returns true if achievement is unlocked.
  bool isUnlocked(String id) {
    return _unlockedCache.contains(id);
  }

  /// Returns next locked achievement based on survival time.
  /// Useful for showing "Next Milestone" during gameplay.
  TimeAchievement? getNextLockedAchievement() {
    for (final achievement in _sortedAchievements) {
      if (!_unlockedCache.contains(achievement.id)) {
        return achievement;
      }
    }
    return null; // All unlocked
  }

  /// Returns all achievement definitions (read-only).
  List<TimeAchievement> getAllAchievements() {
    return List.unmodifiable(_sortedAchievements);
  }

  /// Reset achievements (for debug/testing).
  Future<void> resetAll() async {
    _unlockedCache.clear();
    await _box.put(_unlockedKey, <String>[]);
  }
}
