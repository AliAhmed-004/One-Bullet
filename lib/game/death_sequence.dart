import 'dart:async';

import 'package:one_bullet/components/player.dart';
import 'package:one_bullet/components/player_death_effect.dart';
import 'package:one_bullet/components/shockwave.dart';
import 'package:one_bullet/one_bullet_game.dart';
import 'package:one_bullet/services/achievement_service.dart';
import 'package:one_bullet/services/ad_service.dart';
import 'package:one_bullet/services/score_service.dart';
import 'package:one_bullet/services/sound_service.dart';

/// Runs everything that happens between the killing hit and the game over
/// screen: score + achievement checks, death animation, interstitial ad.
class DeathSequence {
  DeathSequence(this._game);

  final OneBulletGame _game;

  /// Time to let the death animation play before ad / overlay.
  static const Duration _animationDuration = Duration(milliseconds: 1200);

  Timer? _timer;

  /// Starts the sequence for [player]. The caller already marked the run as
  /// game over.
  void begin(Player player) {
    final run = _game.run;
    final position = player.position.clone();

    // Remove player from the world instantly.
    player.removeFromParent();

    _game.juice
      ..hitStop(0.12)
      ..shake(12);
    _game.world.add(
      Shockwave(
        position: position,
        color: Player.playerColor,
        maxRadius: 90,
        duration: 0.45,
        strokeWidth: 5,
      ),
    );

    final secondsSurvived = run.survivalTime.value.inSeconds;

    // Decide achievements now but only unlock once game over is visible.
    run.unlockedAchievements = AchievementService.instance
        .getAchievementsForSurvivalTime(secondsSurvived);

    // Local high score save; leaderboard sync happens later.
    run.isNewHighScore = ScoreService.checkAndSaveHighScoreLocally(
      run.survivalTime.value,
    );

    _game.world.addAll(
      PlayerDeathEffect.createFragments(
        position: position,
        color: Player.playerColor,
        fragmentCount: 14,
        baseSpeed: 300.0,
      ),
    );

    if (run.isNewHighScore) {
      SoundService.playHighScore();
    } else {
      SoundService.playPlayerDeath();
    }

    // Engine keeps running so the animation plays.
    _timer?.cancel();
    _timer = Timer(_animationDuration, () => _onAnimationDone(secondsSurvived));
  }

  /// Cancels a pending sequence (restart / return to menu / dispose).
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _onAnimationDone(int secondsSurvived) {
    _game.pauseEngine();
    SoundService.stopAll();

    final showedInterstitial = AdService.onPlayerDeath(
      secondsSurvived,
      onInterstitialDismissed: () {
        // Small delay after ad dismissal for a smoother transition.
        Future.delayed(const Duration(milliseconds: 200), _showGameOver);
      },
    );

    if (!showedInterstitial) {
      _showGameOver();
    }
  }

  void _showGameOver() {
    final run = _game.run;
    if (!run.isGameOver) return;

    cancel();

    _game.pauseEngine();
    SoundService.stopAll();

    _game.overlays.remove(OneBulletGame.gameHudOverlayId);
    _game.overlays.add(OneBulletGame.gameOverOverlayId);

    // Native Play Games popups show over the game over screen.
    final achievements = run.unlockedAchievements;
    if (achievements.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        AchievementService.instance.unlockAchievements(achievements);
      });
    }

    // Leaderboard sync is async and non-blocking.
    if (run.isNewHighScore) {
      ScoreService.saveScoreToGooglePlayGames(run.survivalTime.value);
    }
  }
}
