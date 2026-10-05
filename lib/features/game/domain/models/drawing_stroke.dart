import 'dart:ui';

/// One continuous line in a drawing round. Points are normalised to the
/// canvas (0–1 on both axes) so the sketch scales to any screen.
class DrawingStroke {
  DrawingStroke({required this.playerId, required List<Offset> points})
      : points = List.unmodifiable(points);

  final String playerId;
  final List<Offset> points;
}
