import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 180, scrollable: find.byType(Scrollable).first);
}

void main() {
  testWidgets('complete private reveal, discussion, ballots and rematch', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayScreen(
          players: [
            Player(id: 'a', name: 'Ali'),
            Player(id: 'b', name: 'Sara'),
            Player(id: 'c', name: 'Omar'),
          ],
          words: [WordEntry(value: 'Pizza', category: 'Food')],
          imposterCount: 1,
          discussionMinutes: 1,
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      expect(find.text('Pizza'), findsNothing);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hold to reveal')),
      );
      await tester.pump();
      expect(find.text('Hold to reveal'), findsNothing);
      await gesture.up();
      await tester.pump();
      expect(find.text('Pizza'), findsNothing);
      final next = find.text(i == 2 ? 'Start discussion' : 'Hide & pass');
      await reveal(tester, next);
      await tester.tap(next);
      await tester.pump();
    }
    await reveal(tester, find.text('Start private voting'));
    await tester.tap(find.text('Start private voting'));
    await tester.pump();
    for (final pair in [('Ali', 'Sara'), ('Sara', 'Ali'), ('Omar', 'Sara')]) {
      await reveal(tester, find.text('I am ${pair.$1}'));
      await tester.tap(find.text('I am ${pair.$1}'));
      await tester.pump();
      await tester.tap(find.text(pair.$2));
      await tester.pump();
      await reveal(tester, find.text('Submit private vote'));
      await tester.tap(find.text('Submit private vote'));
      await tester.pump();
    }
    expect(find.text('THE SECRET WORD'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    await reveal(tester, find.text('Play again'));
    await tester.tap(find.text('Play again'));
    await tester.pump();
    expect(find.text('Pass to Ali'), findsOneWidget);
    expect(find.text('Pizza'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding hides a held role card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayScreen(
          players: [
            Player(id: 'a', name: 'Ali'),
            Player(id: 'b', name: 'Sara'),
            Player(id: 'c', name: 'Omar'),
          ],
          words: [WordEntry(value: 'Pizza', category: 'Food')],
          imposterCount: 1,
          discussionMinutes: 1,
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to reveal')),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Hold to reveal'), findsOneWidget);
    expect(find.text('Pizza'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await gesture.up();
    await tester.pump();
    expect(find.text('Hold to reveal'), findsOneWidget);
  });

  testWidgets('home and setup support landscape and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const SuspectoApp());
    await reveal(tester, find.text('Start game'));
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();
    expect(find.text('Gather your suspects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
