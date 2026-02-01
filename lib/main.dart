import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:one_bullet/one_bullet_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Flame.device.fullScreen();
  Flame.device.setPortrait();
  
  runApp(const OneBullet());
}

class OneBullet extends StatelessWidget {
  const OneBullet({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: OneBulletGame());
  }
}