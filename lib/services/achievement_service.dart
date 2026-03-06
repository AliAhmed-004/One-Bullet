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

  /// Achievements confirmed unlocked in Play Games.
  /// Populated by [syncUnlockedAchievements].
  final Set<String> _playGamesUnlocked = {};

  /// Whether we've successfully synced with Play Games at least once.
  bool _hasSyncedWithPlayGames = false;

  /// ===============================
  /// INIT
  /// ===============================

  Future<void> init() async {
    debugPrint('[ACHIEVEMENT SERVICE] Initializing');

    _timeAchievements = kSurvivalAchievements.toList()
      ..sort((a, b) => a.requiredSeconds.compareTo(b.requiredSeconds));
  }

  /// ===============================
  /// PLAY GAMES SYNC
  /// ===============================

  /// Syncs unlocked achievements from Play Games Services.
  /// Call this after sign-in to know which achievements are already unlocked.
  ///
  /// This method is fire-and-forget to avoid blocking app startup.
  /// The game will work fine without sync; it just won't skip already-unlocked
  /// achievements in the "Next Achievement" UI.
  void syncUnlockedAchievements() {
    if (!PlayGamesService.instance.isSignedIn) {
      debugPrint('[ACHIEVEMENT SERVICE] Cannot sync: not signed in');
      return;
    }

    // Fire-and-forget: schedule sync after first frame to ensure main thread
    // Don't await - we don't want to block app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSync();
    });
  }

  /// Internal sync implementation - runs on main thread after first frame.
  Future<void> _performSync() async {
    try {
      debugPrint('[ACHIEVEMENT SERVICE] Starting achievement sync...');
      final achievements = await gs.Achievements.loadAchievements(
        ignoreImages: true,
      );
      if (achievements == null) {
        debugPrint('[ACHIEVEMENT SERVICE] loadAchievements returned null');
        return;
      }

      _playGamesUnlocked.clear();
      for (final item in achievements) {
        if (item.unlocked) {
          _playGamesUnlocked.add(item.id);
          debugPrint('[ACHIEVEMENT SERVICE] Already unlocked: ${item.id}');
        }
      }

      _hasSyncedWithPlayGames = true;
      debugPrint(
        '[ACHIEVEMENT SERVICE] Synced ${_playGamesUnlocked.length} unlocked achievements',
      );
    } catch (e) {
      debugPrint('[ACHIEVEMENT SERVICE] Sync failed: $e');
      // Sync failure is non-fatal - game continues without knowing
      // which achievements are already unlocked
    }
  }

  /// ===============================
  /// SURVIVAL CHECK
  /// ===============================

  /// Checks which achievements the player has earned for the given survival time.
  /// Does NOT unlock them with Play Games - call [unlockAchievements] separately.
  List<Achievement> getAchievementsForSurvivalTime(int seconds) {
    debugPrint('[ACHIEVEMENT SERVICE] Checking survival time: $seconds');

    final earned = <Achievement>[];

    for (final achievement in _timeAchievements) {
      if (seconds >= achievement.requiredSeconds &&
          !_sessionUnlocked.contains(achievement.id)) {
        earned.add(achievement);
      }
    }

    // Mark as session-unlocked to prevent duplicate popups
    _sessionUnlocked.addAll(earned.map((a) => a.id));

    return earned;
  }

  /// Unlocks the given achievements with Play Games Services.
  /// Call this after the Game Over overlay is shown so the native popup
  /// appears at the right time.
  Future<void> unlockAchievements(List<Achievement> achievements) async {
    if (achievements.isEmpty) return;

    if (!PlayGamesService.instance.isSignedIn) {
      debugPrint('[ACHIEVEMENT SERVICE] Play Games not signed in');
      return;
    }

    for (final achievement in achievements) {
      if (achievement.id.startsWith('debug_')) continue;

      try {
        final gsAchievement = gs.Achievement(
          androidID: achievement.id,
          iOSID: achievement.id,
          percentComplete: 100,
          showsCompletionBanner: true,
        );

        await gs.Achievements.unlock(achievement: gsAchievement);

        // Update local cache so getNextTarget() skips this achievement
        _playGamesUnlocked.add(achievement.id);

        debugPrint(
          '[ACHIEVEMENT SERVICE] Play Games unlock sent: ${achievement.id}',
        );
      } catch (e) {
        debugPrint(
          '[ACHIEVEMENT SERVICE] Play Games unlock failed: ${achievement.id}',
        );
      }
    }
  }

  /// ===============================
  /// NEXT TARGET (UI hint)
  /// ===============================

  /// Returns the next achievement to unlock, considering:
  /// 1. Achievements already unlocked in Play Games (skipped)
  /// 2. Current survival time (shows next target the player hasn't reached yet)
  ///
  /// If Play Games sync hasn't happened, falls back to time-based logic only.
  TimeAchievement? getNextTarget(int seconds) {
    for (final achievement in _timeAchievements) {
      // Skip debug achievements in release mode
      if (achievement.id.startsWith('debug_') && !kDebugMode) continue;

      // Skip achievements already unlocked in Play Games
      if (_playGamesUnlocked.contains(achievement.id)) continue;

      // Return the first achievement the player hasn't reached time-wise
      if (seconds < achievement.requiredSeconds) {
        return achievement;
      }
    }
    return null;
  }

  /// Returns true if all achievements have been unlocked in Play Games.
  bool get allAchievementsUnlocked {
    if (!_hasSyncedWithPlayGames) return false;

    for (final achievement in _timeAchievements) {
      if (achievement.id.startsWith('debug_')) continue;
      if (!_playGamesUnlocked.contains(achievement.id)) return false;
    }
    return true;
  }
}
