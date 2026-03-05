import 'dart:async';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';

class PlayGamesService {
  PlayGamesService._internal();
  static final PlayGamesService instance = PlayGamesService._internal();

  bool _isInitialized = false;
  bool _isSignedIn = false;

  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _isSignedIn;

  /// Initialize Play Games Services.
  /// Call this once during app startup.
  Future<void> initialize() async {
    debugPrint('[PLAY GAMES SERVICE] Initializing Play Games Services...');
    if (_isInitialized) return;

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
      debugPrint('Play Games signed in: ${PlayGamesService.instance.isSignedIn}');
      // Note: Achievement sync is deferred to OneBulletGame.onLoad() to ensure main thread context
    } catch (e) {
      debugPrint('[PLAY GAMES SERVICE] Silent sign-in failed: $e');
      _isSignedIn = false;
    }
  }

  Future<bool> signIn() async {
    debugPrint('[PLAY GAMES SERVICE] Attempting manual sign-in...');
    try {
      final result = await GameAuth.signIn();

      _isSignedIn = true; // ← ALSO HERE
      debugPrint('[PLAY GAMES SERVICE] Manual sign-in successful: $result');
      return true;
    } catch (e) {
      debugPrint('[PLAY GAMES SERVICE] Manual sign-in failed: $e');
      _isSignedIn = false;
      return false;
    }
  }

  /// show achievements
  Future<void> showAchievements() async {
    if (!_isSignedIn) {
      debugPrint('[PLAY GAMES SERVICE] Cannot show achievements: not signed in');
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
