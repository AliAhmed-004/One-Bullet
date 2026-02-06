import 'package:flame_audio/flame_audio.dart';
import 'package:one_bullet/services/settings_service.dart';

class SoundService {
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

  static void playDeflectorBreak() {
    if (SettingsService.soundEnabled.value) {
      FlameAudio.play("deflector_break.wav", volume: 0.7);
    }
  }

  static void playBulletBounce() {
    if (SettingsService.soundEnabled.value) {
      FlameAudio.play("bullet_bounce.wav", volume: 0.5);
    }
  }

  static void playBulletFire() {
    if (SettingsService.soundEnabled.value) {
      FlameAudio.play("bullet_fire.wav", volume: 0.8);
    }
  }

  static void playPlayerDeath() {
    if (SettingsService.soundEnabled.value) {
      FlameAudio.play("player_death.wav", volume: 0.9);
    }
  }

  static void playHighScore() {
    if (SettingsService.soundEnabled.value) {
      FlameAudio.play("high_score.wav", volume: 1.0);
    }
  }

  static void playWaveWarning() {
    if (SettingsService.soundEnabled.value) {
      FlameAudio.play("wave_warning.mp3", volume: 0.3);
    }
  }
}