import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'my_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GameWidget(game: MyGame()));
}
