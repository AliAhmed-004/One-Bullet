import 'package:flame/game.dart';
import 'package:one_bullet/components/player.dart';

class OneBulletGame extends FlameGame {
  OneBulletGame({super.children});

  @override
  Future<void> onLoad() async {
    // Load your game assets and initialize your game here.
    await super.onLoad();

    // Add the player
    world.add(Player(position: Vector2.all(0)));
  }
}
