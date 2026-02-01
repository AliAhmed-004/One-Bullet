import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:one_bullet/components/mobile_joystick.dart';
import 'package:one_bullet/components/player.dart';

/// The main game class for One Bullet.
///
/// Uses HasKeyboardHandlerComponents to enable keyboard input for components.
/// Uses HasDraggablesBridge to enable drag/touch input for mobile joystick.
class OneBulletGame extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks {
  OneBulletGame({super.children});

  /// Reference to the player for easy access.
  Player? player;

  /// Reference to the mobile joystick for touch controls.
  MobileJoystick? joystick;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create and add the player at the center of the world
    player = Player(position: Vector2.zero());
    world.add(player!);

    // Add the mobile joystick (renders in screen space, not world space)
    joystick = MobileJoystick(player: player!);
    camera.viewport.add(joystick!);
  }
}

