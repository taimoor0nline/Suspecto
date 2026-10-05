import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/drawing_canvas.dart';

/// Pass-the-phone sketching: each player adds one line per turn to a shared
/// drawing of their word, without writing letters or numbers.
class DrawingPhase extends StatelessWidget {
  const DrawingPhase(
      {super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  @override
  Widget build(BuildContext context) {
    final drawer = round.drawer;
    final last = round.drawTurn == round.drawTurns - 1;
    return PhasePage(
      title: 'Pass to ${drawer.name}',
      subtitle:
          'Line ${round.drawTurn + 1} of ${round.drawTurns}. Add one line to the drawing. No letters or numbers!',
      onEndRound: onEndRound,
      children: [
        DrawingCanvas(
          players: round.players,
          strokes: round.strokes,
          pen: round.pen,
          penPlayer: drawer,
          onPenDown: round.penDown,
          onPenMove: round.penMove,
          onPenUp: round.penUp,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: round.lineDrawn ? round.undoLine : null,
          icon: const Icon(Icons.undo),
          label: const LocalText('Redo my line'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: round.lineDrawn
              ? () {
                  StoreScope.maybeOf(context)?.feedback();
                  round.passDrawing();
                }
              : null,
          child: LocalText(last ? 'Start discussion' : 'Done, pass the phone'),
        ),
      ],
    );
  }
}
