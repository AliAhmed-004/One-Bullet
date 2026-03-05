import 'dart:async';
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
    print('[PLAY GAMES SERVICE] Initializing Play Games Services...');
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
    print('[PLAY GAMES SERVICE] Attempting silent sign-in...');
    try {
      final result = await GameAuth.signIn();

      _isSignedIn = true;
      print('[PLAY GAMES SERVICE] Silent sign-in successful: $result');
      print('Play Games signed in: ${PlayGamesService.instance.isSignedIn}');
      // Note: Achievement sync is deferred to OneBulletGame.onLoad() to ensure main thread context
    } catch (e) {
      print('[PLAY GAMES SERVICE] Silent sign-in failed: $e');
      _isSignedIn = false;
    }
  }

  Future<bool> signIn() async {
    print('[PLAY GAMES SERVICE] Attempting manual sign-in...');
    try {
      final result = await GameAuth.signIn();

      _isSignedIn = true; // ← ALSO HERE
      print('[PLAY GAMES SERVICE] Manual sign-in successful: $result');
      return true;
    } catch (e) {
      print('[PLAY GAMES SERVICE] Manual sign-in failed: $e');
      _isSignedIn = false;
      return false;
    }
  }
}
