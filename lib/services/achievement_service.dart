import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:one_bullet/services/play_games_service.dart';

/// ===============================
/// ACHIEVEMENT DEFINITIONS (Domain Layer)
/// ===============================

abstract class Achievement {
  final String id; // Play Games ID (or local debug ID)
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
/// ACHIEVEMENTS LIST
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

  static const String _boxName = 'achievements';
  static const String _unlockedKey = 'unlocked';

  late final Box _box;

  final Set<String> _unlockedCache = {};

  late final Map<String, Achievement> _achievementMap;
  late final List<TimeAchievement> _timeAchievements;

  int get unlockedCount => _unlockedCache.length;

  /// ===============================
  /// INIT
  /// ===============================

  Future<void> init() async {
    log("[ACHIEVEMENT SERVICE] Initializing...");

    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);

    final stored = _box.get(_unlockedKey);
    if (stored is List) {
      _unlockedCache
        ..clear()
        ..addAll(stored.cast<String>());
    }

    _achievementMap = {for (final a in kAllAchievements) a.id: a};

    _timeAchievements = kSurvivalAchievements.toList()
      ..sort((a, b) => a.requiredSeconds.compareTo(b.requiredSeconds));

    log('[ACHIEVEMENT SERVICE] Loaded unlocked: $_unlockedCache');
  }

  /// ===============================
  /// GETTERS
  /// ===============================

  Set<String> getUnlockedIds() => Set.unmodifiable(_unlockedCache);

  Achievement? getAchievementById(String id) => _achievementMap[id];

  List<Achievement> getAllAchievements() =>
      List.unmodifiable(kAllAchievements);

  bool isUnlocked(String id) => _unlockedCache.contains(id);

  /// ===============================
  /// SURVIVAL TIME CHECK
  /// ===============================

  Future<List<Achievement>> checkAndUnlockForSurvivalTime(
    int seconds,
  ) async {
    log("[ACHIEVEMENT SERVICE] Checking survival time: $seconds seconds");

    final newlyUnlocked = <Achievement>[];

    for (final achievement in _timeAchievements) {
      if (seconds >= achievement.requiredSeconds &&
          !_unlockedCache.contains(achievement.id)) {
        newlyUnlocked.add(achievement);
      }
    }

    if (newlyUnlocked.isEmpty) return [];

    // 1️⃣ Save locally (source of truth)
    _unlockedCache.addAll(newlyUnlocked.map((a) => a.id));
    await _box.put(_unlockedKey, _unlockedCache.toList());

    // 2️⃣ Sync to Play Games (translation layer)
    if (PlayGamesService.instance.isSignedIn) {
      log('[ACHIEVEMENT SERVICE] PlayGames signed in: ${PlayGamesService.instance.isSignedIn}');
      for (final achievement in newlyUnlocked) {
        // Skip debug-only achievements
        if (achievement.id.startsWith('debug_')) continue;

        try {
          final gsAchievement = gs.Achievement(
            androidID: achievement.id,
            iOSID: achievement.id,
            percentComplete: 100,
            showsCompletionBanner: true,
          );

          await gs.Achievements.unlock(
            achievement: gsAchievement,
          );

          log(
            '[ACHIEVEMENT SERVICE] Synced to Play Games: ${achievement.id}',
          );
        } catch (e) {
          log(
            '[ACHIEVEMENT SERVICE] Play Games unlock failed for ${achievement.id}: $e',
          );
        }
      }
    }

    log(
      "[ACHIEVEMENT SERVICE] Newly unlocked: ${newlyUnlocked.map((a) => a.id).toList()}",
    );

    return newlyUnlocked;
  }

  /// ===============================
  /// NEXT TARGET
  /// ===============================

  TimeAchievement? getNextLockedTimeAchievement() {
    for (final achievement in _timeAchievements) {
      if (!_unlockedCache.contains(achievement.id)) {
        return achievement;
      }
    }
    return null;
  }

  /// ===============================
  /// DEBUG / RESET
  /// ===============================

  Future<void> resetAll() async {
    _unlockedCache.clear();
    await _box.put(_unlockedKey, <String>[]);
  }
}