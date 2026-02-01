import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Player extends CircleComponent {
  Player({required Vector2 position, Color? color})
    : super(
        anchor: Anchor.center,
        radius: 20,
        paint: Paint()
          ..color = color ?? Colors.blue
          ..style = PaintingStyle.fill,
      );
}
