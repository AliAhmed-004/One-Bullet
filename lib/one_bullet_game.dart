import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:one_bullet/components/bullet.dart';
import 'package:one_bullet/components/mobile_joystick.dart';
import 'package:one_bullet/components/player.dart';

/// The main game class for One Bullet.
///
/// Uses HasKeyboardHandlerComponents to enable keyboard input for components.
/// Uses TapCallbacks to handle tap-to-fire mechanic.
class OneBulletGame extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, TapCallbacks {
  OneBulletGame({super.children});

  /// Reference to the player for easy access.
  Player? player;

  /// Reference to the mobile joystick for touch controls.
  MobileJoystick? joystick;

  /// Reference to the bullet (only one exists).
  Bullet? bullet;

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

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Don't fire if already fired or if tapping in joystick zone
    if (player == null || player!.hasFired) return;

    // Check if tap is in the joystick activation zone (bottom quarter)
    // If so, don't fire - let the joystick handle it
    if (event.canvasPosition.y >= size.y * 0.75) return;

    // Fire the bullet!
    _fireBullet();
  }

  /// Fires the bullet in the current aim direction.
  void _fireBullet() {
    if (player == null || player!.hasFired) return;

    // Get the aim direction from the player's aim indicator
    final aimDirection = player!.aimDirection;

    // Calculate bullet spawn position (at the edge of the player + offset)
    final spawnOffset = aimDirection * (player!.radius + 15);
    final spawnPosition = player!.position + spawnOffset;

    // Create and add the bullet
    bullet = Bullet(
      position: spawnPosition,
      direction: aimDirection,
    );
    world.add(bullet!);

    // Mark player as having fired
    player!.markAsFired();
  }
}

