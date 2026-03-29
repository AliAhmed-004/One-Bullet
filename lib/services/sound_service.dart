import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:one_bullet/services/settings_service.dart';

class SoundService {
  static AudioPlayer? waveWarningPlayer;
  static final List<AudioPlayer> _activePlayers = [];
  static bool _audioBackendAvailable = true;

  /// Tracks when each player was added (ms). Used for TTL-based pruning
  /// as a fallback when onPlayerComplete or PlayerState are unreliable on Android.
  static final Map<AudioPlayer, int> _playerAddedMs = {};

  /// Last timestamp (ms) each SFX was played, used for throttling.
  static final Map<String, int> _lastSfxPlayMs = {};

  /// Limit concurrent one-shot players to reduce audio churn under stress.
  static const int _maxActivePlayers = 32;

  /// All SFX are short clips; 5 s TTL safely covers the longest one.
  static const int _playerTtlMs = 5000;

  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'deflector_break.wav',
        'bullet_bounce.wav',
        'bullet_fire.wav',
        'player_death.wav',
        'high_score.wav',
        'wave_warning.wav',
      ]);
      _audioBackendAvailable = true;
    } catch (e) {
      _audioBackendAvailable = false;
      debugPrint('SoundService: audio backend unavailable during init: $e');
    }
  }

  static void pauseAll() {
    for (final player in _activePlayers) {
      player.pause();
    }
  }

  static void resumeAll() {
    for (final player in _activePlayers) {
      player.resume();
    }
  }

  static void stopAll() {
    for (final player in _activePlayers) {
      player.stop();
    }
    _activePlayers.clear();
    _playerAddedMs.clear();
    // Do NOT clear _lastSfxPlayMs — preserving throttle history prevents a
    // burst of re-triggering immediately after a restart/menu transition.
    waveWarningPlayer = null;
  }

  static Future<void> _playSfx(
    String file, {
    required double volume,
    int minIntervalMs = 0,
  }) async {
    if (!SettingsService.soundEnabled.value || !_audioBackendAvailable) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final previousMs = _lastSfxPlayMs[file] ?? 0;
    if (minIntervalMs > 0 && nowMs - previousMs < minIntervalMs) {
      return;
    }

    // Prune finished players. Two strategies because both onPlayerComplete and
    // PlayerState are unreliable for short clips on Android:
    //   1. State check  — fast path when state IS updated correctly.
    //   2. TTL eviction — removes any player older than _playerTtlMs regardless.
    _activePlayers.removeWhere((p) {
      if (p.state == PlayerState.stopped || p.state == PlayerState.completed) {
        _playerAddedMs.remove(p);
        return true;
      }
      if (nowMs - (_playerAddedMs[p] ?? nowMs) > _playerTtlMs) {
        _playerAddedMs.remove(p);
        p.stop();
        return true;
      }
      return false;
    });

    // Enforce an upper bound to prevent runaway player creation.
    if (_activePlayers.length >= _maxActivePlayers) {
      return;
    }

    _lastSfxPlayMs[file] = nowMs;

    try {
      final player = await FlameAudio.play(file, volume: volume);
      _playerAddedMs[player] = nowMs;
      _activePlayers.add(player);

      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
        _playerAddedMs.remove(player);
      });
    } catch (e) {
      _audioBackendAvailable = false;
      debugPrint('[SoundService]: failed to play SFX "$file": $e');
    }
  }

  static void playDeflectorBreak() {
    _playSfx('deflector_break.wav', volume: 0.7, minIntervalMs: 20);
  }

  static void playBulletBounce() {
    _playSfx('bullet_bounce.wav', volume: 0.5, minIntervalMs: 35);
  }

  static void playBulletFire() {
    _playSfx('bullet_fire.wav', volume: 0.8);
  }

  static void playPlayerDeath() {
    _playSfx('player_death.wav', volume: 0.6);
  }

  static void playHighScore() {
    _playSfx('high_score.wav', volume: 1.0);
  }

  static Future<void> playWaveWarning() async {
    if (!SettingsService.soundEnabled.value || !_audioBackendAvailable) return;
    // Guard against double-play, but check PlayerState rather than just
    // non-null — onPlayerComplete may never fire on Android, leaving
    // waveWarningPlayer non-null even after the audio finished.
    if (waveWarningPlayer?.state == PlayerState.playing) return;
    if (waveWarningPlayer != null) {
      _activePlayers.remove(waveWarningPlayer);
      waveWarningPlayer = null;
    }

    try {
      waveWarningPlayer = await FlameAudio.play('wave_warning.wav', volume: 0.6);
      _activePlayers.add(waveWarningPlayer!);

      waveWarningPlayer!.onPlayerComplete.listen((_) {
        _activePlayers.remove(waveWarningPlayer);
        waveWarningPlayer = null;
      });
    } catch (e) {
      _audioBackendAvailable = false;
      debugPrint('[SoundService]: failed to play wave warning: $e');
    }
  }
}
