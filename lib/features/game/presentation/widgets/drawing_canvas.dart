import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/game/domain/models/drawing_stroke.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/profiles/domain/player_profile.dart';

/// A square sketch made of normalised [strokes], each in its drawer's
/// colour. With [onPenDown], [onPenMove] and [onPenUp] it takes one line at a
/// time; it claims touches first so a drag draws instead of scrolling.
class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({
    super.key,
    required this.players,
    required this.strokes,
    this.pen,
    this.penPlayer,
    this.onPenDown,
    this.onPenMove,
    this.onPenUp,
  });

  final List<Player> players;
  final List<DrawingStroke> strokes;

  /// The line in progress and who is drawing it.
  final List<Offset>? pen;
  final Player? penPlayer;

  final ValueChanged<Offset>? onPenDown;
  final ValueChanged<Offset>? onPenMove;
  final VoidCallback? onPenUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = StoreScope.maybeOf(context);
    Color colorOf(String playerId) {
      final name = players.firstWhere((p) => p.id == playerId).name;
      final look =
          store?.lookOf(name) ?? PlayerProfile.defaultFor(name, id: '');
      return Color(look.color);
    }

    final lines = [
      for (final stroke in strokes) (colorOf(stroke.playerId), stroke.points),
      if (pen != null && penPlayer != null) (colorOf(penPlayer!.id), pen!),
    ];
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, box) {
          final size = box.biggest;
          Offset norm(Offset local) =>
              Offset(local.dx / size.width, local.dy / size.height);
          final canvas = CustomPaint(
            size: size,
            painter: _SketchPainter(lines),
          );
          if (onPenDown == null) {
            return canvas;
          }
          return RawGestureDetector(
            gestures: {
              EagerGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => onPenDown!(norm(e.localPosition)),
              onPointerMove: (e) => onPenMove?.call(norm(e.localPosition)),
              onPointerUp: (_) => onPenUp?.call(),
              onPointerCancel: (_) => onPenUp?.call(),
              child: canvas,
            ),
          );
        }),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.lines);
  final List<(Color, List<Offset>)> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.shortestSide / 70;
    for (final (color, points) in lines) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final scaled = [
        for (final p in points) Offset(p.dx * size.width, p.dy * size.height),
      ];
      if (scaled.length == 1) {
        canvas.drawCircle(
            scaled.first, width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(scaled.first.dx, scaled.first.dy);
      for (final p in scaled.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SketchPainter old) => true;
}
