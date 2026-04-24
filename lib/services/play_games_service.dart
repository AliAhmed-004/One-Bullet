import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:one_bullet/services/achievement_service.dart';

class PlayGamesService {
  PlayGamesService._internal();
  static final PlayGamesService instance = PlayGamesService._internal();

  static const String _androidLeaderboardId = "CgkIvLXzppUPEAIQBw";
  // Add this later if you support Game Center
  // static const String _iosLeaderboardId = "your_ios_leaderboard_id";

  bool _isInitialized = false;
  bool _isSignedIn = false;
  final ValueNotifier<bool> signInState = ValueNotifier(false);

  Future<void>? _initFuture;
  StreamSubscription<PlayerData?>? _authSubscription;

  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _isSignedIn;

  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String get _leaderboardId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidLeaderboardId;
      default:
        throw UnsupportedError('Play Games is not supported on this platform.');
    }
  }

  /// Safe one-time initialization.
  /// Can be called multiple times without race conditions.
  Future<void> initialize() {
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    debugPrint('[PLAY GAMES] Initializing...');

    if (!isSupportedPlatform) {
      _isInitialized = true;
      _isSignedIn = false;
      debugPrint('[PLAY GAMES] Unsupported platform, skipping initialization');
      return;
    }

    _attachAuthListener();
    await _refreshSignInState();

    _isInitialized = true;

    debugPrint(
      '[PLAY GAMES] Initialization complete | signed in: $_isSignedIn',
    );
  }

  void _attachAuthListener() {
    _authSubscription ??= GameAuth.player.listen((player) {
      final signedIn = player != null;
      _updateSignInState(signedIn);
    });
  }

  Future<void> _refreshSignInState() async {
    try {
      final signedIn = await GameAuth.isSignedIn;
      await _updateSignInState(signedIn);
    } catch (e) {
      debugPrint('[PLAY GAMES] Sign-in state check failed: $e');
      await _updateSignInState(false);
    }
  }

  Future<void> _updateSignInState(bool signedIn) async {
    if (_isSignedIn == signedIn) return;

    _isSignedIn = signedIn;
    signInState.value = signedIn;

    debugPrint('[PLAY GAMES] Auth state changed | signed in: $_isSignedIn');

    if (_isSignedIn) {
      unawaited(AchievementService.instance.syncUnlockedAchievements());
    }
  }

  /// Manual sign-in flow.
  Future<bool> signIn() async {
    if (!isSupportedPlatform) {
      debugPrint('[PLAY GAMES] Sign-in skipped: unsupported platform');
      return false;
    }

    debugPrint('[PLAY GAMES] Attempting manual sign-in...');

    try {
      final result = await GameAuth.signIn();

      final signedIn = await GameAuth.isSignedIn;
      await _updateSignInState(signedIn);

      debugPrint(
        '[PLAY GAMES] Sign-in result: $result | signed in: $_isSignedIn',
      );

      return _isSignedIn;
    } catch (e) {
      debugPrint('[PLAY GAMES] Manual sign-in failed: $e');
      await _updateSignInState(false);
      return false;
    }
  }

  Future<void> showLeaderboards() async {
    if (!_canUseService('show leaderboards')) return;

    try {
      await GamesServices.showLeaderboards();
      debugPrint('[PLAY GAMES] Leaderboards opened');
    } catch (e) {
      debugPrint('[PLAY GAMES] Failed to show leaderboards: $e');
    }
  }

  Future<List<LeaderboardScoreData>> loadLeaderboardScores({
    int maxResults = 10,
  }) async {
    if (!_canUseService('load leaderboard scores')) {
      return [];
    }

    try {
      final scores = await GamesServices.loadLeaderboardScores(
        maxResults: maxResults,
        androidLeaderboardID: _leaderboardId,
        timeScope: TimeScope.allTime,
        scope: PlayerScope.global,
      );

      if (scores == null || scores.isEmpty) {
        debugPrint('[PLAY GAMES] No leaderboard scores found');
        return [];
      }

      debugPrint('[PLAY GAMES] Loaded ${scores.length} leaderboard scores');

      return scores;
    } catch (e) {
      debugPrint('[PLAY GAMES] Failed to load scores: $e');
      return [];
    }
  }

  Future<void> showAchievements() async {
    if (!_canUseService('show achievements')) return;

    try {
      await GamesServices.showAchievements();
      debugPrint('[PLAY GAMES] Achievements opened');
    } catch (e) {
      debugPrint('[PLAY GAMES] Failed to show achievements: $e');
    }
  }

  bool _canUseService(String action) {
    if (!isSupportedPlatform) {
      debugPrint('[PLAY GAMES] Cannot $action: unsupported platform');
      return false;
    }

    if (!_isSignedIn) {
      debugPrint('[PLAY GAMES] Cannot $action: user not signed in');
      return false;
    }

    return true;
  }

  /// Cleanup for tests / app shutdown / hot restart.
  Future<void> dispose() async {
    debugPrint('[PLAY GAMES] Disposing service...');

    await _authSubscription?.cancel();
    _authSubscription = null;

    _initFuture = null;
    _isInitialized = false;
    _isSignedIn = false;
  }
}
