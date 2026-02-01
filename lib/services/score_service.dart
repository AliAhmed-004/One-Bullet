import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  /// Checks if the given score is a new high score and saves it if so.
  /// Returns true if it's a new record.
  static bool checkAndSaveHighScore(Duration score) {
    if (score > highScore.value) {
      highScore.value = score;
      _box?.put(_highScoreKey, score.inMilliseconds);
      return true;
    }
    return false;
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
