import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';
import 'package:suspecto/features/game/presentation/widgets/drawing_canvas.dart';

const _players = [
  Player(id: 'a', name: 'Ali'),
  Player(id: 'b', name: 'Sara'),
  Player(id: 'c', name: 'Omar'),
];
const _words = [WordEntry(value: 'Pizza', category: 'Food')];

RoundController _controller(GameOptions options) => RoundController(
      players: _players,
      words: _words,
      imposterCount: 1,
      discussionMinutes: 1,
      options: options,
    );

void _revealAll(RoundController round) {
  for (var i = 0; i < _players.length; i++) {
    round
      ..showCard(true)
      ..showCard(false)
      ..nextCard();
  }
}

void main() {
  test('each player draws one line per lap from the starting player', () {
    final round = _controller(const GameOptions(drawing: true));
    _revealAll(round);
    expect(round.phase, RoundPhase.drawing);
    final start =
        _players.indexWhere((p) => p.id == round.session.startingPlayerId);
    final drawers = <String>[];
    for (var turn = 0; turn < round.drawTurns; turn++) {
      drawers.add(round.drawer.id);
      round.passDrawing();
      expect(round.drawTurn, turn, reason: 'cannot pass without a line');
      round
        ..penDown(const Offset(0.2, 0.2))
        ..penMove(const Offset(2, -1))
        ..penUp();
      expect(round.lineDrawn, isTrue);
      round.penDown(const Offset(0.5, 0.5));
      expect(round.pen, isNull, reason: 'one line per turn');
      round
        ..undoLine()
        ..penDown(const Offset(0.1, 0.1))
        ..penUp()
        ..passDrawing();
    }
    expect(drawers, [
      for (var i = 0; i < round.drawTurns; i++)
        _players[(start + i) % _players.length].id,
    ]);
    expect(round.phase, RoundPhase.discussion);
    expect(round.strokes, hasLength(round.drawTurns));
    expect(round.strokes.first.points.single, const Offset(0.1, 0.1));
    round.playAgain();
    expect(round.strokes, isEmpty);
    round.dispose();
  });

  test('drawing is skipped when off and in question mode', () {
    for (final options in const [
      GameOptions(),
      GameOptions(drawing: true, mode: GameMode.questions),
    ]) {
      final round = _controller(options);
      _revealAll(round);
      expect(round.phase, RoundPhase.discussion);
      round.dispose();
    }
  });

  testWidgets('dragging on the canvas draws instead of scrolling',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PlayScreen(
        players: _players,
        words: _words,
        imposterCount: 1,
        discussionMinutes: 1,
        options: GameOptions(drawing: true),
      ),
    ));
    for (var i = 0; i < 3; i++) {
      final gesture = await tester
          .startGesture(tester.getCenter(find.text('Hold to reveal')));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      final next = find.text(i == 2 ? 'Start discussion' : 'Hide & pass');
      await tester.scrollUntilVisible(next, 180,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.byType(DrawingCanvas), findsOneWidget);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final before = scroll.position.pixels;
    await tester.drag(find.byType(DrawingCanvas), const Offset(0, -150));
    await tester.pump();
    expect(scroll.position.pixels, before);
    final done = find.text('Done, pass the phone');
    await tester.scrollUntilVisible(done, 180,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<FilledButton>(
                find.ancestor(of: done, matching: find.byType(FilledButton)))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });
}
