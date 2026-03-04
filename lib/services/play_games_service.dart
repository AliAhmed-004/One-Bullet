import 'dart:async';
import 'dart:developer';
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
    log('[PLAY GAMES SERVICE] Initializing Play Games Services...');
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

  /// Attempt silent authentication.
  Future<void> _attemptSilentSignIn() async {
    log('[PLAY GAMES SERVICE] Attempting silent sign-in...');
    try {
      final result = await GameAuth.signIn();

      log('[PLAY GAMES SERVICE] Sign-in successful: $result');

    } catch (e) {
      log('[PLAY GAMES SERVICE] Silent sign-in failed: $e');
      _isSignedIn = false;
    }
  }

  /// Manual sign-in trigger (call from settings button, etc.)
  Future<bool> signIn() async {
    log('[PLAY GAMES SERVICE] Attempting manual sign-in...');
    try {
      final result = await GameAuth.signIn();
      log('[PLAY GAMES SERVICE] Manual sign-in successful: $result');
      return true;
    } catch (e) {
      log('[PLAY GAMES SERVICE] Manual sign-in failed: $e');
      _isSignedIn = false;
      return false;
    }
  }

  /// Sign out if needed (optional)
  // Future<void> signOut() async {
  //   try {
  //     await GamesServices.signOut();
  //     _isSignedIn = false;
  //   } catch (_) {
  //     _isSignedIn = false;
  //   }
  // }
}