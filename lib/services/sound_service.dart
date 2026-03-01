import 'package:flame_audio/flame_audio.dart';
import 'package:one_bullet/services/settings_service.dart';

class SoundService {
  static AudioPlayer? waveWarningPlayer;
  static final List<AudioPlayer> _activePlayers = [];

  /// Last timestamp (ms) each SFX was played, used for throttling.
  static final Map<String, int> _lastSfxPlayMs = {};

  /// Limit concurrent one-shot players to reduce audio churn under stress.
  static const int _maxActivePlayers = 24;

  static Future<void> init() async {
    // Preload sound effects
    await FlameAudio.audioCache.loadAll([
      'deflector_break.wav',
      'bullet_bounce.wav',
      'bullet_fire.wav',
      'player_death.wav',
      'high_score.wav',
      'wave_warning.wav',
    ]);
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
    _lastSfxPlayMs.clear();
    waveWarningPlayer = null;
  }

  static Future<void> _playSfx(
    String file, {
    required double volume,
    int minIntervalMs = 0,
  }) async {
    if (!SettingsService.soundEnabled.value) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final previousMs = _lastSfxPlayMs[file] ?? 0;
    if (minIntervalMs > 0 && nowMs - previousMs < minIntervalMs) {
      return;
    }

    // Enforce an upper bound to prevent runaway player creation.
    if (_activePlayers.length >= _maxActivePlayers) {
      return;
    }

    _lastSfxPlayMs[file] = nowMs;

    final player = await FlameAudio.play(file, volume: volume);
    _activePlayers.add(player);

    player.onPlayerComplete.listen((_) {
      _activePlayers.remove(player);
    });
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
    if (!SettingsService.soundEnabled.value) return;
    if (waveWarningPlayer != null) return;

    waveWarningPlayer = await FlameAudio.play('wave_warning.wav', volume: 0.6);
    _activePlayers.add(waveWarningPlayer!);

    waveWarningPlayer!.onPlayerComplete.listen((_) {
      _activePlayers.remove(waveWarningPlayer);
      waveWarningPlayer = null;
    });
  }
}
