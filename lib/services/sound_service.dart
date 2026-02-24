// import 'package:flame_audio/flame_audio.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:one_bullet/services/settings_service.dart';

class SoundService {
  static AudioPlayer? waveWarningPlayer;
  static final List<AudioPlayer> _activePlayers = [];

  static Future<void> init() async {
    // Preload sound effects
    await FlameAudio.audioCache.loadAll([
      "deflector_break.wav",
      "bullet_bounce.wav",
      "bullet_fire.wav",
      "player_death.wav",
      "high_score.wav",
      "wave_warning.mp3",
    ]);
  }

  static void pauseAll() {
    // Pause all sound effects except background music
    for (var player in _activePlayers) {
      player.pause();
    }
  }

  static void resumeAll() {
    // Resume all sound effects
    for (var player in _activePlayers) {
      player.resume();
    }
  }

  static void stopAll() {
    // Stop all sound effects
    for (var player in _activePlayers) {
      player.stop();
    }
    _activePlayers.clear();
  }

  static void playDeflectorBreak() async {
    if (SettingsService.soundEnabled.value) {
      AudioPlayer player = await FlameAudio.play(
        "deflector_break.wav",
        volume: 0.7,
      );
      _activePlayers.add(player);
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
      });
    }
  }

  static void playBulletBounce() async {
    if (SettingsService.soundEnabled.value) {
      AudioPlayer player = await FlameAudio.play(
        "bullet_bounce.wav",
        volume: 0.5,
      );
      _activePlayers.add(player);
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
      });
    }
  }

  static void playBulletFire() async {
    if (SettingsService.soundEnabled.value) {
      AudioPlayer player = await FlameAudio.play(
        "bullet_fire.wav",
        volume: 0.8,
      );
      _activePlayers.add(player);
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
      });
    }
  }

  static void playPlayerDeath() async {
    if (SettingsService.soundEnabled.value) {
      AudioPlayer player = await FlameAudio.play(
        "player_death.wav",
        volume: 0.6,
      );
      _activePlayers.add(player);
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
      });
    }
  }

  static void playHighScore() async {
    if (SettingsService.soundEnabled.value) {
      AudioPlayer player = await FlameAudio.play("high_score.wav", volume: 1.0);
      _activePlayers.add(player);
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
      });
    }
  }

  static void playWaveWarning() async {
    if (SettingsService.soundEnabled.value) {
      waveWarningPlayer = await FlameAudio.play(
        "wave_warning.mp3",
        volume: 0.3,
      );
      _activePlayers.add(waveWarningPlayer!);
      waveWarningPlayer!.onPlayerComplete.listen((_) {
        _activePlayers.remove(waveWarningPlayer);
        waveWarningPlayer = null;
      });
    }
  }
}
