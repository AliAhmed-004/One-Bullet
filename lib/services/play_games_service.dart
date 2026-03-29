import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:one_bullet/services/achievement_service.dart';

class PlayGamesService {
  PlayGamesService._internal();
  static final PlayGamesService instance = PlayGamesService._internal();

  bool _isInitialized = false;
  bool _isSignedIn = false;

  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _isSignedIn;

  static bool get _supportsPlayGames =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initialize Play Games Services.
  /// Call this once during app startup.
  Future<void> initialize() async {
    debugPrint('[PLAY GAMES SERVICE] Initializing Play Games Services...');
    if (_isInitialized) return;

    if (!_supportsPlayGames) {
      _isInitialized = true;
      _isSignedIn = false;
      debugPrint(
        '[PLAY GAMES SERVICE] Skipping initialization on unsupported platform',
      );
      return;
    }

    try {
      await _attemptSilentSignIn();
      _isInitialized = true;
    } catch (e) {
      // We don't crash the game because of Play Games.
      _isInitialized = true;
      _isSignedIn = false;
    }
  }

  Future<void> _attemptSilentSignIn() async {
    debugPrint('[PLAY GAMES SERVICE] Attempting silent sign-in...');
    try {
      final result = await GameAuth.signIn();

      _isSignedIn = true;
      debugPrint('[PLAY GAMES SERVICE] Silent sign-in successful: $result');
      debugPrint(
        'Play Games signed in: ${PlayGamesService.instance.isSignedIn}',
      );

      // Sync unlocked achievements from Play Games (fire-and-forget)
      AchievementService.instance.syncUnlockedAchievements();
    } catch (e) {
      debugPrint('[PLAY GAMES SERVICE] Silent sign-in failed: $e');
      _isSignedIn = false;
    }
  }

  Future<bool> signIn() async {
    if (!_supportsPlayGames) {
      debugPrint('[PLAY GAMES SERVICE] Sign-in skipped on unsupported platform');
      return false;
    }

    debugPrint('[PLAY GAMES SERVICE] Attempting manual sign-in...');
    try {
      final result = await GameAuth.signIn();

      _isSignedIn = true;
      debugPrint('[PLAY GAMES SERVICE] Manual sign-in successful: $result');

      // Sync unlocked achievements from Play Games (fire-and-forget)
      AchievementService.instance.syncUnlockedAchievements();

      return true;
    } catch (e) {
      debugPrint('[PLAY GAMES SERVICE] Manual sign-in failed: $e');
      _isSignedIn = false;
      return false;
    }
  }

  // show leaderboards
  Future<void> showLeaderboards() async {
    if (!_supportsPlayGames) {
      debugPrint(
        '[PLAY GAMES SERVICE] Cannot show leaderboards: unsupported platform',
      );
      return;
    }

    if (!_isSignedIn) {
      debugPrint(
        '[PLAY GAMES SERVICE] Cannot show leaderboards: not signed in',
      );
      return;
    }

    try {
      await GamesServices.showLeaderboards();
      debugPrint('[PLAY GAMES SERVICE] Show leaderboards successful');
    } catch (e) {
      debugPrint('[PLAY GAMES SERVICE] Show leaderboards failed: $e');
    }
  }

  /// show achievements
  Future<void> showAchievements() async {
    if (!_supportsPlayGames) {
      debugPrint(
        '[PLAY GAMES SERVICE] Cannot show achievements: unsupported platform',
      );
      return;
    }

    if (!_isSignedIn) {
      debugPrint(
        '[PLAY GAMES SERVICE] Cannot show achievements: not signed in',
      );
      return;
    }

    try {
      await GamesServices.showAchievements();
      debugPrint('[PLAY GAMES SERVICE] Show achievements successful');
    } catch (e) {
      debugPrint('[PLAY GAMES SERVICE] Show achievements failed: $e');
    }
  }
}
