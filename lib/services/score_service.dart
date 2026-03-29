import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:one_bullet/services/play_games_service.dart';

/// Service for managing high scores using Hive local storage.
class ScoreService {
  static const String _boxName = 'scores';
  static const String _highScoreKey = 'highScore';

  static Box? _box;

  /// The current high score as a ValueNotifier for reactive UI updates.
  static final ValueNotifier<Duration> highScore = ValueNotifier(Duration.zero);

  /// Initializes Hive and loads the saved high score.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);

    // Load saved high score
    final savedMilliseconds = _box?.get(_highScoreKey, defaultValue: 0) as int;
    highScore.value = Duration(milliseconds: savedMilliseconds);
  }

  /// Checks if the given score is a new high score and saves it locally only.
  /// This is fast and non-blocking. Leaderboard sync happens separately.
  /// Returns true if it's a new record.
  static bool checkAndSaveHighScoreLocally(Duration score) {
    if (score > highScore.value) {
      highScore.value = score;
      final box = _box;
      if (box != null) {
        // Fire-and-forget local save; Hive is fast enough
        unawaited(box.put(_highScoreKey, score.inMilliseconds));
      }
      return true;
    }
    return false;
  }

  static Future<void> saveScoreToGooglePlayGames(Duration score) async {
    if (!PlayGamesService.instance.isSignedIn) {
      return;
    }

    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: 'CgkIvLXzppUPEAIQBw',
          value: score.inMilliseconds,
        ),
      );
    } catch (e) {
      debugPrint('[SCORE SERVICE] Failed to submit leaderboard score: $e');
    }
  }

  /// Formats a duration as MM:SS string.
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Resets the high score (for debugging/testing).
  static void resetHighScore() {
    highScore.value = Duration.zero;
    _box?.put(_highScoreKey, 0);
  }
}
