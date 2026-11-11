import 'package:flutter/foundation.dart';
import 'package:one_bullet/services/achievement_service.dart';

/// Mutable state of the current run, plus the notifiers the UI listens to.
class RunState {
  /// Whether the player has dismissed the start screen.
  bool hasStarted = false;

  /// Whether the player is dead.
  bool isGameOver = false;

  /// Whether the user paused the game.
  bool isPaused = false;

  /// Whether the single "continue" for this run was already spent.
  bool hasUsedContinue = false;

  /// Whether the latest finished run beat the stored high score.
  bool isNewHighScore = false;

  /// Achievements earned by the latest finished run (unlocked after the
  /// game over screen is visible).
  List<Achievement> unlockedAchievements = const [];

  /// Survival time shown by the HUD (updated every [_uiInterval]).
  final ValueNotifier<Duration> survivalTime = ValueNotifier(Duration.zero);

  /// Current wave number and flash state shown by the HUD.
  final ValueNotifier<({int waveNumber, bool isFlashing})> waveState =
      ValueNotifier((waveNumber: 1, isFlashing: false));

  static const double _uiInterval = 0.1;

  double _elapsedSeconds = 0;
  double _uiAccumulator = 0;

  /// True while the run is live: started, alive and not paused.
  bool get isActive => hasStarted && !isGameOver && !isPaused;

  /// Resets everything for a fresh run.
  void reset() {
    hasStarted = false;
    isGameOver = false;
    isPaused = false;
    hasUsedContinue = false;
    isNewHighScore = false;
    unlockedAchievements = const [];
    _elapsedSeconds = 0;
    _uiAccumulator = 0;
    survivalTime.value = Duration.zero;
    waveState.value = (waveNumber: 1, isFlashing: false);
  }

  /// Advances the survival clock. Notifies listeners at most every 100 ms.
  void tick(double dt) {
    _elapsedSeconds += dt;
    _uiAccumulator += dt;

    if (_uiAccumulator >= _uiInterval) {
      survivalTime.value = Duration(
        milliseconds: (_elapsedSeconds * 1000).toInt(),
      );
      _uiAccumulator = 0;
    }
  }

  void dispose() {
    survivalTime.dispose();
    waveState.dispose();
  }
}
