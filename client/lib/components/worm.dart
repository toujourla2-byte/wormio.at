import 'package:flame/components.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'dart:ui';

class Worm extends PositionComponent {
  final String id;
  Vector2 velocity = Vector2.zero();
  final int segmentsCount;
  final double segmentSpacing;
  List<Vector2> segmentPositions = [];
  Paint bodyPaint = Paint()..color = const Color(0xFFFF6B6B);
  Paint headPaint = Paint()..color = const Color(0xFF4DA6FF);

  Worm({
    required this.id,
    Vector2? initialPosition,
    this.segmentsCount = 8,
    this.segmentSpacing = 14.0,
  }) : super(position: initialPosition ?? Vector2.zero()) {
    for (int i = 0; i < segmentsCount; i++) {
      segmentPositions.add(position.clone());
    }
    size = Vector2.all(segmentSpacing * 2);
  }

  void setVelocity(Vector2 v) {
    velocity = v;
  }

  void serverSetPosition(Vector2 serverPos) {
    final target = serverPos.clone();
    position = Vector2.lerp(position, target, 0.4)!;
    for (int i = 0; i < segmentPositions.length; i++) {
      segmentPositions[i] = Vector2.lerp(segmentPositions[i], position, 0.25)!;
    }
  }

  void applyInput(Vector2 input) {
    velocity = input;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    Vector2 prev = position.clone();
    for (int i = 0; i < segmentPositions.length; i++) {
      Vector2 dir = prev - segmentPositions[i];
      double dist = dir.length;
      if (dist > 0.001) {
        dir.normalize();
        final desired = prev - dir * segmentSpacing;
        segmentPositions[i] = Vector2.lerp(segmentPositions[i], desired, 0.5)!;
      }
      prev = segmentPositions[i].clone();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (int i = segmentPositions.length - 1; i >= 0; i--) {
      final p = segmentPositions[i];
      final radius = lerpDouble(6, 12, i / segmentPositions.length)!;
      canvas.drawCircle(Offset(p.x, p.y), radius, bodyPaint);
    }

    canvas.drawCircle(Offset(position.x, position.y), 12, headPaint);

    final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
    final pupil = Paint()..color = const Color(0xFF111111);

    final dir = velocity.length > 0.1 ? velocity.normalized() : Vector2(0, -1);
    final perp = Vector2(-dir.y, dir.x);
    final left = position + dir * -2 + perp * -6;
    final right = position + dir * -2 + perp * 6;

    canvas.drawCircle(Offset(left.x, left.y), 3, eyePaint);
    canvas.drawCircle(Offset(right.x, right.y), 3, eyePaint);
    canvas.drawCircle(Offset(left.x, left.y), 1.5, pupil);
    canvas.drawCircle(Offset(right.x, right.y), 1.5, pupil);
  }
}
