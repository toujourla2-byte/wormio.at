import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

import 'components/worm.dart';
import 'networking/network_client.dart';

class MyGame extends FlameGame with HasDraggables, HasTappables {
  late NetworkClient net;
  late Worm localWorm;
  final String playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';

  final Map<String, dynamic> remoteWorms = {};

  int localTick = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // create local worm roughly centered
    localWorm = Worm(id: playerId, initialPosition: Vector2(size.x / 2, size.y / 2));
    add(localWorm);

    // network client
    net = NetworkClient('ws://localhost:8080');
    await net.connect();
    net.sendJoin(playerId);

    // listen for server state updates
    net.onState = (state) {
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final players = state['players'] as List<dynamic>? ?? [];
      for (final p in players) {
        final id = p['id'] as String;
        final x = (p['x'] as num).toDouble();
        final y = (p['y'] as num).toDouble();
        if (id == playerId) {
          localWorm.serverSetPosition(Vector2(x, y));
        } else {
          // For now we just ignore remote players; RemoteWorms will be added in next steps
          // Keep a simple store so future steps can create RemoteWorm components
          remoteWorms[id] = {'x': x, 'y': y, 't': nowSec};
        }
      }
    };

    // simple keyboard input handling (for desktop testing)
    RawKeyboard.instance.addListener(_handleKey);
  }

  void _handleKey(RawKeyEvent e) {
    final isDown = e is RawKeyDownEvent;
    // Use logicalKey debugName for arrows; fall back to keyLabel for letters
    final keyLabel = e.logicalKey.keyLabel.toLowerCase();
    Vector2 v = Vector2.zero();
    if (isDown) {
      if (keyLabel == 'w' || e.logicalKey == LogicalKeyboardKey.arrowUp) v = Vector2(0, -160);
      if (keyLabel == 's' || e.logicalKey == LogicalKeyboardKey.arrowDown) v = Vector2(0, 160);
      if (keyLabel == 'a' || e.logicalKey == LogicalKeyboardKey.arrowLeft) v = Vector2(-160, 0);
      if (keyLabel == 'd' || e.logicalKey == LogicalKeyboardKey.arrowRight) v = Vector2(160, 0);
    }

    localWorm.setVelocity(v);
    // send input with tick
    localTick++;
    net.sendInputWithTick(playerId, v, localTick);
  }

  @override
  void onRemove() {
    RawKeyboard.instance.removeListener(_handleKey);
    net.dispose();
    super.onRemove();
  }
}
