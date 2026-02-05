import 'package:flame_audio/flame_audio.dart';

class SoundService {
  static Future<void> init() async {
    // Preload sound effects
    await FlameAudio.audioCache.loadAll([
      "deflector_break.wav",
      "bullet_bounce.wav",
      "bullet_fire.wav",
      "player_death.wav",
    ]);
  } 

  static void playDeflectorBreak() {
    FlameAudio.play("deflector_break.wav", volume: 0.7);
  }

  static void playBulletBounce() {
    FlameAudio.play("bullet_bounce.wav", volume: 0.5);
  }

  static void playBulletFire() {
    FlameAudio.play("bullet_fire.wav", volume: 0.8);
  }

  static void playPlayerDeath() {
    FlameAudio.play("player_death.wav", volume: 0.9);
  }
}